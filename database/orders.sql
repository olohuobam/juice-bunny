-- ═══════════════════════════════════════════════════════════
--  JUICE BUNNY — STORE ORDERS
--  Run in: Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════

create table if not exists public.orders (
  id             uuid primary key default gen_random_uuid(),
  order_number   text unique not null default ('JB' || to_char(now(),'YYMMDD') || '-' || upper(substr(md5(random()::text),1,5))),
  user_id        uuid references public.profiles(id) on delete set null,

  -- Contact + shipping (captured at checkout, even for guests)
  email          text not null,
  full_name      text not null,
  phone          text,
  address_line1  text not null,
  address_line2  text,
  city           text not null,
  state_region   text,
  postal_code    text not null,
  country        text not null,

  -- Money
  subtotal_usd   numeric(10,2) not null default 0,
  shipping_usd   numeric(10,2) not null default 0,
  total_usd      numeric(10,2) not null default 0,

  -- Lifecycle
  status         text not null default 'pending'
                 check (status in ('pending','paid','processing','shipped','delivered','cancelled','refunded')),
  payment_method text,                          -- 'card' | 'crypto' | null (pre-launch)
  payment_ref    text,
  tracking_number text,

  notes          text,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

create index if not exists orders_user_idx   on public.orders(user_id);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists orders_created_idx on public.orders(created_at desc);


create table if not exists public.order_items (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references public.orders(id) on delete cascade,
  product_id   uuid references public.products(id) on delete set null,
  product_name text not null,          -- snapshot, survives product deletion
  emoji        text,
  unit_price   numeric(10,2) not null,
  quantity     integer not null default 1,
  line_total   numeric(10,2) not null
);

create index if not exists order_items_order_idx on public.order_items(order_id);


-- ── RLS ──────────────────────────────────────────────────────
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

-- Buyers see their own orders; admins see all
drop policy if exists "Users see own orders" on public.orders;
create policy "Users see own orders"
  on public.orders for select using (
    user_id = auth.uid() or public.is_admin()
  );

-- Anyone (incl. guest checkout) can create an order
drop policy if exists "Anyone can place an order" on public.orders;
create policy "Anyone can place an order"
  on public.orders for insert with check (true);

-- Only admins change order status / tracking
drop policy if exists "Admins update orders" on public.orders;
create policy "Admins update orders"
  on public.orders for update using (public.is_admin());

-- Order items follow their order
drop policy if exists "See items of visible orders" on public.order_items;
create policy "See items of visible orders"
  on public.order_items for select using (
    public.is_admin() or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id and o.user_id = auth.uid()
    )
  );

drop policy if exists "Anyone can add order items" on public.order_items;
create policy "Anyone can add order items"
  on public.order_items for insert with check (true);


-- ── Helper: deduct stock when an order is placed ─────────────
create or replace function public.place_order_item(
  p_order_id uuid, p_product_id uuid, p_name text, p_emoji text,
  p_unit numeric, p_qty integer
) returns void
language plpgsql security definer as $$
begin
  insert into public.order_items(order_id, product_id, product_name, emoji, unit_price, quantity, line_total)
  values (p_order_id, p_product_id, p_name, p_emoji, p_unit, p_qty, p_unit * p_qty);

  -- decrement stock if the product still exists and tracks stock
  if p_product_id is not null then
    update public.products
      set stock_units = greatest(0, coalesce(stock_units,0) - p_qty)
      where id = p_product_id;
  end if;
end;
$$;


-- ── GRANTS (API roles) ───────────────────────────────────────
grant select, insert          on public.orders      to anon, authenticated;
grant update                  on public.orders      to authenticated;
grant select, insert          on public.order_items to anon, authenticated;
grant execute on function public.place_order_item(uuid,uuid,text,text,numeric,integer) to anon, authenticated;

-- updated_at trigger
drop trigger if exists orders_updated_at on public.orders;
create trigger orders_updated_at
  before update on public.orders
  for each row execute function public.handle_updated_at();

-- realtime for the admin orders view
alter publication supabase_realtime add table public.orders;

select 'orders schema ready' as status;
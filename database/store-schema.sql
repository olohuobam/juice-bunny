-- ═══════════════════════════════════════════════════════════
--  JUICE BUNNY STORE — products table
--  Run in: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════

create table if not exists public.products (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  category    text not null check (category in ('supplements','gym','wellness','intimacy')),
  price_usd   numeric(10,2) not null,
  image_url   text,
  emoji       text default '🛍️',
  in_stock    boolean default true,
  is_active   boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

alter table public.products enable row level security;

drop policy if exists "Anyone can view active products" on public.products;
create policy "Anyone can view active products"
  on public.products for select using (is_active = true);

drop policy if exists "Admins can manage products" on public.products;
create policy "Admins can manage products"
  on public.products for all using (public.is_admin());

drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at
  before update on public.products
  for each row execute function public.handle_updated_at();

-- ── Launch catalog seed ─────────────────────────────────────
insert into public.products (name, description, category, price_usd, emoji) values
('Bunny Boost — Performance Supplement','Daily energy & stamina blend. 60 capsules.','supplements',29.99,'⚡'),
('Juice Greens — Superfood Powder','30 servings of greens, adaptogens & gut support.','supplements',34.99,'🥬'),
('Midnight Recovery — Sleep & Muscle','Magnesium + zinc night-time recovery formula.','supplements',24.99,'🌙'),
('JB Resistance Bands — 5-Level Set','Five resistance levels with carry pouch.','gym',19.99,'💪'),
('Bunny Grip — Lifting Straps','Padded wrist straps for heavy pulls.','gym',14.99,'🏋️'),
('JB Shaker — Insulated 700ml','Leak-proof, keeps drinks cold for 12h.','gym',16.99,'🥤'),
('Glow Ritual — Massage Oil','Warming botanical massage oil, 120ml.','wellness',22.99,'✨'),
('Deep Calm — Aromatherapy Candle','Sandalwood & vanilla, 40h burn.','wellness',18.99,'🕯️'),
('Bunny Kiss — Couples Set','Curated couples kit. Ships discreet.','intimacy',49.99,'💋'),
('Silk Touch — Personal Lubricant','Water-based, body-safe, 250ml.','intimacy',15.99,'💧'),
('After Dark — Enhancement Supplement','Herbal enhancement blend for him & her.','intimacy',39.99,'🔥'),
('Velvet Blindfold — Satin','Soft satin with adjustable strap.','intimacy',12.99,'🎀');
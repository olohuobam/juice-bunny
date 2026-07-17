-- ═══════════════════════════════════════════════════════════
--  JUICE BUNNY STORE — v2 columns (detail page support)
--  Run AFTER store-schema.sql. Safe to re-run.
-- ═══════════════════════════════════════════════════════════

alter table public.products add column if not exists sale_price  numeric(10,2);           -- crossed-out original when set
alter table public.products add column if not exists stock_units integer default 0;       -- units in stock
alter table public.products add column if not exists images      text[] default '{}';      -- gallery: array of image URLs

-- Keep in_stock in sync with stock_units automatically
create or replace function public.sync_product_stock()
returns trigger as $$
begin
  new.in_stock := coalesce(new.stock_units,0) > 0;
  return new;
end;
$$ language plpgsql;

drop trigger if exists products_stock_sync on public.products;
create trigger products_stock_sync
  before insert or update on public.products
  for each row execute function public.sync_product_stock();

-- Give the seeded catalog some demo stock + a couple of launch sales
update public.products set stock_units = 40 where stock_units = 0 or stock_units is null;
update public.products set sale_price = 37.49, stock_units = 25 where name like 'Bunny Kiss%';   -- was 49.99
update public.products set sale_price = 31.99, stock_units = 60 where name like 'After Dark%';   -- was 39.99
update public.products set sale_price = 27.99, stock_units = 12 where name like 'Juice Greens%'; -- was 34.99
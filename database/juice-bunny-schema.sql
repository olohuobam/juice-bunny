-- ═══════════════════════════════════════════════════════════
--  JUICE BUNNY — Supabase Database Schema
--  Run this in: Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════


-- ── 1. PROFILES ─────────────────────────────────────────────
-- Stores user info linked to Supabase Auth
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  email         text unique not null,
  full_name     text,
  avatar_url    text,
  date_of_birth date,
  country       text,
  plan          text not null default 'free' check (plan in ('free','basic','bunnyworld')),
  status        text not null default 'active' check (status in ('active','inactive','banned')),
  role          text not null default 'user' check (role in ('user','model','admin')),
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Admins can view all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );


-- ── 2. SUBSCRIPTIONS ────────────────────────────────────────
-- Tracks active and past subscriptions
create table if not exists public.subscriptions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.profiles(id) on delete cascade,
  plan            text not null check (plan in ('free','basic','bunnyworld')),
  billing_period  text check (billing_period in ('weekly','monthly','biannual')),
  status          text not null default 'active' check (status in ('active','cancelled','expired','paused')),
  started_at      timestamptz default now(),
  expires_at      timestamptz,
  cancelled_at    timestamptz,
  created_at      timestamptz default now()
);

alter table public.subscriptions enable row level security;

create policy "Users can view their own subscriptions"
  on public.subscriptions for select
  using (auth.uid() = user_id);

create policy "Admins can view all subscriptions"
  on public.subscriptions for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );


-- ── 3. VIDEOS ───────────────────────────────────────────────
-- Video metadata (actual files live on Cloudflare Stream)
create table if not exists public.videos (
  id                  uuid primary key default gen_random_uuid(),
  title               text not null,
  description         text,
  category            text check (category in ('Action','Romance','Anime','Originals','Steamy','Live Call')),
  thumbnail_url       text,
  thumbnail_emoji     text default '🎬',
  duration            text,
  cloudflare_video_id text,         -- populated when Cloudflare Stream is wired in
  is_premium          boolean default true,
  is_featured         boolean default false,
  is_active           boolean default true,
  view_count          integer default 0,
  uploaded_by         uuid references public.profiles(id),
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

alter table public.videos enable row level security;

-- Free videos visible to everyone
create policy "Anyone can view free videos"
  on public.videos for select
  using (is_premium = false and is_active = true);

-- Premium videos visible to paying subscribers only
create policy "Premium users can view premium videos"
  on public.videos for select
  using (
    is_active = true and (
      is_premium = false
      or exists (
        select 1 from public.subscriptions
        where user_id = auth.uid()
        and plan in ('basic','bunnyworld')
        and status = 'active'
        and (expires_at is null or expires_at > now())
      )
    )
  );

-- Admins can do everything
create policy "Admins can manage videos"
  on public.videos for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );


-- ── 4. PAYMENTS ─────────────────────────────────────────────
-- All payment records (NOWPayments crypto + CCBill cards)
create table if not exists public.payments (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid references public.profiles(id) on delete set null,
  user_email          text,
  plan                text not null check (plan in ('basic','bunnyworld')),
  billing_period      text check (billing_period in ('weekly','monthly','biannual')),
  amount_usd          numeric(10,2) not null,
  currency            text,          -- BTC, ETH, USDT, LTC, XRP, USD
  payment_method      text check (payment_method in ('nowpayments','ccbill')),
  provider_payment_id text,          -- NOWPayments payment_id or CCBill transaction ID
  status              text not null default 'pending' check (status in ('pending','finished','failed','expired','refunded')),
  nowpayments_data    jsonb,         -- raw webhook payload from NOWPayments
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

alter table public.payments enable row level security;

create policy "Users can view their own payments"
  on public.payments for select
  using (auth.uid() = user_id);

create policy "Admins can view all payments"
  on public.payments for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Allow inserts from webhook (service role only — handled server-side)
create policy "Service role can insert payments"
  on public.payments for insert
  with check (true);


-- ── 5. VIDEO VIEWS ──────────────────────────────────────────
-- Track who watched what (for analytics)
create table if not exists public.video_views (
  id         uuid primary key default gen_random_uuid(),
  video_id   uuid references public.videos(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete set null,
  watched_at timestamptz default now()
);

alter table public.video_views enable row level security;

create policy "Anyone can insert a view"
  on public.video_views for insert
  with check (true);

create policy "Admins can read views"
  on public.video_views for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );


-- ── 6. BROADCAST HISTORY ────────────────────────────────────
create table if not exists public.broadcasts (
  id          uuid primary key default gen_random_uuid(),
  type        text check (type in ('email','sms')),
  audience    text,
  subject     text,
  body        text not null,
  sent_count  integer default 0,
  sent_by     uuid references public.profiles(id),
  created_at  timestamptz default now()
);

alter table public.broadcasts enable row level security;

create policy "Admins can manage broadcasts"
  on public.broadcasts for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );


-- ── 7. AUTO-UPDATE updated_at ───────────────────────────────
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

create trigger videos_updated_at
  before update on public.videos
  for each row execute function public.handle_updated_at();

create trigger payments_updated_at
  before update on public.payments
  for each row execute function public.handle_updated_at();


-- ── 8. AUTO-CREATE PROFILE ON SIGNUP ────────────────────────
-- When a user signs up via Supabase Auth, auto-create their profile row
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ── 9. SEED: Admin user placeholder ─────────────────────────
-- After you sign up with admin@juicebunny.com via the app,
-- run this to give that account admin role:
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@juicebunny.com';


-- ═══════════════════════════════════════════════════════════
--  DONE — 6 tables, RLS policies, triggers, auto-profile
-- ═══════════════════════════════════════════════════════════
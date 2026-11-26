-- Run this in Supabase → SQL Editor.
-- Adds the columns the NOWPayments webhook needs to record a verified subscription.
alter table public.profiles
  add column if not exists plan_expires_at timestamptz,
  add column if not exists last_payment_id text;

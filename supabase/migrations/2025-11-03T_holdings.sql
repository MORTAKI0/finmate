-- 2025-11-03T_holdings.sql
-- FinMate • Sprint 2 • S2-T1
-- Creates public.holdings (crypto + cash), updated_at trigger, unique index, and RLS owner policies.

BEGIN;

-- 0) Prereqs (Supabase usually has this already)
create extension if not exists pgcrypto with schema public;

-- 1) Table
create table if not exists public.holdings (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id) on delete cascade,

  type text not null
    check (type in ('crypto','cash')),

  symbol text not null,                      -- crypto ticker OR ISO currency for cash (UPPERCASE via UI)

  quantity numeric(38,10) not null default 0
    check (quantity >= 0),

  cost_basis numeric(38,10) not null default 0
    check (cost_basis >= 0),                 -- stored in user's base currency for now

  note text null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.holdings is 'User-scoped asset positions (crypto & cash).';

-- 2) updated_at trigger (uses a shared helper; safe if it already exists)
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_holdings_updated_at on public.holdings;
create trigger trg_holdings_updated_at
before update on public.holdings
for each row
execute procedure public.set_updated_at();

-- 3) Uniqueness: one position per (user, type, symbol)
create unique index if not exists ux_holdings_user_type_symbol
  on public.holdings (user_id, type, symbol);

-- 4) Row Level Security (owner-only)
alter table public.holdings enable row level security;

drop policy if exists holdings_select_own on public.holdings;
create policy holdings_select_own
  on public.holdings
  for select
  using (auth.uid() = user_id);

drop policy if exists holdings_insert_own on public.holdings;
create policy holdings_insert_own
  on public.holdings
  for insert
  with check (auth.uid() = user_id);

drop policy if exists holdings_update_own on public.holdings;
create policy holdings_update_own
  on public.holdings
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists holdings_delete_own on public.holdings;
create policy holdings_delete_own
  on public.holdings
  for delete
  using (auth.uid() = user_id);

COMMIT;

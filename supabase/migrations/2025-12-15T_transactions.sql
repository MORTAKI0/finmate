-- 2025-12-15T_transactions.sql
-- Adds public.transactions, owner-only RLS, and a trigger to roll transactions into holdings.

begin;

create extension if not exists pgcrypto with schema public;

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  holding_id uuid not null references public.holdings(id) on delete cascade,
  type text not null check (type in ('buy','sell')),
  quantity numeric(38,10) not null check (quantity > 0),
  price_per_unit numeric(38,10) not null check (price_per_unit >= 0),
  executed_at timestamptz not null default now()
);

comment on table public.transactions is 'Per-trade ledger for holdings (buy/sell).';

alter table public.transactions enable row level security;

drop policy if exists transactions_select_own on public.transactions;
create policy transactions_select_own
  on public.transactions
  for select
  using (auth.uid() = user_id);

drop policy if exists transactions_insert_own on public.transactions;
create policy transactions_insert_own
  on public.transactions
  for insert
  with check (auth.uid() = user_id);

drop policy if exists transactions_update_own on public.transactions;
create policy transactions_update_own
  on public.transactions
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists transactions_delete_own on public.transactions;
create policy transactions_delete_own
  on public.transactions
  for delete
  using (auth.uid() = user_id);

create or replace function public.apply_transaction_to_holding()
returns trigger
language plpgsql
as $$
declare
  _prev_qty numeric(38,10);
  _prev_cost numeric(38,10);
  _new_qty numeric(38,10);
  _new_cost numeric(38,10);
  _cost_delta numeric(38,10);
begin
  select quantity, cost_basis into _prev_qty, _prev_cost
  from public.holdings
  where id = new.holding_id
  for update;

  if not found then
    raise exception 'holding % not found for transaction', new.holding_id
      using errcode = '23503';
  end if;

  if new.type = 'buy' then
    _new_qty := coalesce(_prev_qty, 0) + new.quantity;
    _new_cost := coalesce(_prev_cost, 0) + (new.quantity * new.price_per_unit);
  elsif new.type = 'sell' then
    if _prev_qty is null or _prev_qty <= 0 or new.quantity > _prev_qty then
      raise exception 'insufficient quantity to sell (have %, attempted %)', _prev_qty, new.quantity
        using errcode = '22000';
    end if;
    _cost_delta := _prev_cost * (new.quantity / nullif(_prev_qty, 0));
    _new_qty := _prev_qty - new.quantity;
    _new_cost := greatest(_prev_cost - coalesce(_cost_delta, 0), 0);
  else
    raise exception 'unknown transaction type %', new.type;
  end if;

  update public.holdings
    set quantity = _new_qty,
        cost_basis = _new_cost,
        updated_at = now()
    where id = new.holding_id;

  return new;
end;
$$;

drop trigger if exists trg_transactions_apply on public.transactions;
create trigger trg_transactions_apply
after insert on public.transactions
for each row
execute procedure public.apply_transaction_to_holding();

commit;

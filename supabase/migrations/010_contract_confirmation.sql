-- WorkBridge / permit_plans: create an immutable contract snapshot after both
-- parties have agreed to the same quote terms.
-- Requires migrations 001, 002, 005, 007, 008 and 009.
-- IMPORTANT: This does not charge a card, authorize a payment, or hold funds.

create table if not exists public.contracts (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  task_id uuid not null unique references public.tasks(id) on delete restrict,
  quote_id uuid not null unique references public.quotes(id) on delete restrict,
  client_id uuid not null references public.profiles(id) on delete restrict,
  engineer_id uuid not null references public.profiles(id) on delete restrict,
  agreed_amount_minor bigint not null,
  currency text not null,
  delivery_days integer not null,
  scope_of_work text not null,
  included_revisions integer not null default 0,
  notes text,
  commission_bps integer not null default 500,
  platform_fee_minor bigint not null,
  engineer_net_minor bigint not null,
  status text not null default 'awaiting_payment',
  terms_agreed_at timestamptz not null,
  client_confirmed_at timestamptz not null default pg_catalog.now(),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  constraint contracts_amount_positive check (agreed_amount_minor > 0),
  constraint contracts_currency_code check (currency ~ '^[A-Z]{3}$'),
  constraint contracts_delivery_days check (delivery_days between 1 and 3650),
  constraint contracts_scope_length check (
    pg_catalog.length(pg_catalog.btrim(scope_of_work)) between 30 and 6000
  ),
  constraint contracts_revisions_range check (included_revisions between 0 and 10),
  constraint contracts_commission_range check (commission_bps between 0 and 2000),
  constraint contracts_fee_nonnegative check (platform_fee_minor >= 0),
  constraint contracts_engineer_net_nonnegative check (engineer_net_minor >= 0),
  constraint contracts_amount_reconciles check (
    platform_fee_minor + engineer_net_minor = agreed_amount_minor
  ),
  constraint contracts_valid_status check (status in (
    'awaiting_payment', 'funded', 'in_progress', 'submitted',
    'revision_requested', 'completed', 'disputed', 'cancelled',
    'refund_pending', 'refunded'
  )),
  constraint contracts_distinct_parties check (client_id <> engineer_id)
);

create index if not exists contracts_client_status_created_idx
  on public.contracts(client_id, status, created_at desc);
create index if not exists contracts_engineer_status_created_idx
  on public.contracts(engineer_id, status, created_at desc);

alter table public.contracts enable row level security;
revoke all on table public.contracts from anon, authenticated;
grant select on table public.contracts to authenticated;

drop policy if exists "Contract parties can read their contracts" on public.contracts;
create policy "Contract parties can read their contracts"
  on public.contracts for select to authenticated
  using (
    client_id = (select auth.uid())
    or engineer_id = (select auth.uid())
    or exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'admin'
    )
  );

-- Return only the accepted quote's agreed terms and limited public Engineer details.
create or replace function public.get_client_contract_preview(p_quote_id uuid)
returns table (
  quote_id uuid,
  task_id uuid,
  engineer_id uuid,
  engineer_name text,
  engineer_avatar_url text,
  engineer_country text,
  engineer_headline text,
  task_title text,
  task_description text,
  task_category text,
  currency text,
  amount_minor bigint,
  delivery_days integer,
  scope_of_work text,
  included_revisions integer,
  notes text,
  commission_bps integer,
  platform_fee_minor bigint,
  engineer_net_minor bigint,
  contract_id uuid,
  contract_status text,
  confirmed_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid := auth.uid();
  v_role text;
begin
  if v_client_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_client_id;

  if v_role is distinct from 'client' then
    raise exception 'Only Clients can preview their contract' using errcode = '42501';
  end if;

  return query
  select
    q.id,
    t.id,
    q.engineer_id,
    coalesce(nullif(pg_catalog.btrim(ep_base.full_name), ''), 'Engineer')::text,
    ep_base.avatar_url,
    ep_base.country_name,
    ep.headline,
    t.title,
    t.description,
    t.category,
    coalesce(c.currency, q.currency),
    coalesce(c.agreed_amount_minor, q.amount_minor),
    coalesce(c.delivery_days, q.delivery_days),
    coalesce(c.scope_of_work, q.scope_of_work),
    coalesce(c.included_revisions, q.included_revisions),
    coalesce(c.notes, q.notes),
    coalesce(c.commission_bps, 500),
    coalesce(c.platform_fee_minor, round(q.amount_minor::numeric * 500 / 10000)::bigint),
    coalesce(c.engineer_net_minor,
      q.amount_minor - round(q.amount_minor::numeric * 500 / 10000)::bigint),
    c.id,
    c.status,
    c.client_confirmed_at
  from public.quotes q
  join public.tasks t on t.id = q.task_id
  join public.profiles ep_base on ep_base.id = q.engineer_id
  left join public.engineer_profiles ep on ep.user_id = q.engineer_id
  left join public.contracts c on c.quote_id = q.id
  where q.id = p_quote_id
    and q.client_id = v_client_id
    and q.status = 'accepted'
    and t.client_id = v_client_id;
end;
$function$;

revoke all on function public.get_client_contract_preview(uuid) from public, anon;
grant execute on function public.get_client_contract_preview(uuid) to authenticated;

-- Confirming is idempotent and stores a snapshot of the mutually accepted quote.
-- The task is already awaiting_payment after quote acceptance. This RPC does not
-- move funds or alter the task's payment state.
create or replace function public.confirm_accepted_quote_contract(p_quote_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid := auth.uid();
  v_role text;
  v_task_id uuid;
  v_engineer_id uuid;
  v_amount_minor bigint;
  v_currency text;
  v_delivery_days integer;
  v_scope text;
  v_revisions integer;
  v_notes text;
  v_updated_at timestamptz;
  v_existing_contract_id uuid;
  v_contract_id uuid;
  v_commission_bps integer := 500;
  v_fee bigint;
  v_net bigint;
begin
  if v_client_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_client_id;

  if v_role is distinct from 'client' then
    raise exception 'Only Clients can confirm contracts' using errcode = '42501';
  end if;

  -- A retry returns the same contract rather than creating a duplicate.
  select c.id into v_existing_contract_id
  from public.contracts c
  where c.quote_id = p_quote_id and c.client_id = v_client_id;

  if v_existing_contract_id is not null then
    return v_existing_contract_id;
  end if;

  select q.task_id, q.engineer_id, q.amount_minor, q.currency,
         q.delivery_days, q.scope_of_work, q.included_revisions,
         q.notes, q.updated_at
    into v_task_id, v_engineer_id, v_amount_minor, v_currency,
         v_delivery_days, v_scope, v_revisions, v_notes, v_updated_at
  from public.quotes q
  join public.tasks t on t.id = q.task_id
  where q.id = p_quote_id
    and q.client_id = v_client_id
    and q.status = 'accepted'
    and t.client_id = v_client_id
    and t.status = 'awaiting_payment'
  for update of q, t;

  if v_task_id is null then
    raise exception 'Quote is not accepted or task is not awaiting payment' using errcode = 'P0001';
  end if;

  -- Serialize concurrent confirmations for the same task, then re-check
  -- idempotency after the lock (another request may have completed meanwhile).
  perform 1 from public.tasks t where t.id = v_task_id for update;

  select c.id into v_existing_contract_id
  from public.contracts c
  where c.quote_id = p_quote_id and c.client_id = v_client_id;

  if v_existing_contract_id is not null then
    return v_existing_contract_id;
  end if;

  select c.id into v_existing_contract_id
  from public.contracts c
  where c.task_id = v_task_id;

  if v_existing_contract_id is not null then
    raise exception 'This task already has a contract for another quote' using errcode = '23505';
  end if;

  v_fee := round(v_amount_minor::numeric * v_commission_bps / 10000)::bigint;
  v_net := v_amount_minor - v_fee;

  insert into public.contracts (
    task_id, quote_id, client_id, engineer_id,
    agreed_amount_minor, currency, delivery_days, scope_of_work,
    included_revisions, notes, commission_bps,
    platform_fee_minor, engineer_net_minor, status, terms_agreed_at
  ) values (
    v_task_id, p_quote_id, v_client_id, v_engineer_id,
    v_amount_minor, v_currency, v_delivery_days, v_scope,
    v_revisions, v_notes, v_commission_bps,
    v_fee, v_net, 'awaiting_payment', v_updated_at
  )
  returning id into v_contract_id;

  return v_contract_id;
end;
$function$;

revoke all on function public.confirm_accepted_quote_contract(uuid) from public, anon;
grant execute on function public.confirm_accepted_quote_contract(uuid) to authenticated;

comment on table public.contracts is
  'Immutable snapshot of an accepted quote. Does not itself collect, hold or release funds.';
comment on function public.confirm_accepted_quote_contract(uuid) is
  'Creates an idempotent contract snapshot for an accepted quote. It does not charge a card or hold funds.';

notify pgrst, 'reload schema';

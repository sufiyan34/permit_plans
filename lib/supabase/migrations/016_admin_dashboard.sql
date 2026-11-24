-- WorkBridge / permit_plans: Admin dashboard read-only reporting.
-- Requires migrations 001, 002, 005, 007, 010 and 013.
-- This migration creates no moderation actions, payment ledger, escrow,
-- refunds, account suspension, or payout state changes.

create or replace function public.admin_get_dashboard_snapshot()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'admin' then
    raise exception 'Only administrators can view the admin dashboard'
      using errcode = '42501';
  end if;

  select pg_catalog.jsonb_build_object(
    'metrics', pg_catalog.jsonb_build_object(
      'total_users', (select pg_catalog.count(*) from public.profiles),
      'clients', (select pg_catalog.count(*) from public.user_roles where role = 'client'),
      'engineers', (select pg_catalog.count(*) from public.user_roles where role = 'engineer'),
      'admins', (select pg_catalog.count(*) from public.user_roles where role = 'admin'),
      'profiles_completed', (select pg_catalog.count(*) from public.profiles where profile_completed = true),
      'new_users_7d', (select pg_catalog.count(*) from public.profiles where created_at >= pg_catalog.now() - interval '7 days'),
      'total_tasks', (select pg_catalog.count(*) from public.tasks),
      'pending_invitations', (select pg_catalog.count(*) from public.task_invitations where status = 'pending'),
      'quotes_pending_review', (select pg_catalog.count(*) from public.quotes where status = 'pending_client_review'),
      'quotes_negotiating', (select pg_catalog.count(*) from public.quotes where status in ('client_countered', 'engineer_countered')),
      'contracts_awaiting_payment', (select pg_catalog.count(*) from public.contracts where status = 'awaiting_payment'),
      'contracts_active', (select pg_catalog.count(*) from public.contracts where status in ('funded', 'in_progress')),
      'contracts_submitted', (select pg_catalog.count(*) from public.contracts where status = 'submitted'),
      'contracts_revision_requested', (select pg_catalog.count(*) from public.contracts where status = 'revision_requested'),
      'contracts_completed', (select pg_catalog.count(*) from public.contracts where status = 'completed'),
      'contracts_attention', (select pg_catalog.count(*) from public.contracts where status in ('disputed', 'refund_pending')),
      'deliveries_submitted', (select pg_catalog.count(*) from public.project_deliveries where status = 'submitted'),
      'deliveries_revision_requested', (select pg_catalog.count(*) from public.project_deliveries where status = 'revision_requested')
    ),
    'payment_monitor', pg_catalog.jsonb_build_object(
      'provider_integrated', false,
      'ledger_available', false,
      'awaiting_payment_contracts', (select pg_catalog.count(*) from public.contracts where status = 'awaiting_payment'),
      'contracts_marked_funded_or_started', (select pg_catalog.count(*) from public.contracts where status in ('funded', 'in_progress', 'submitted', 'revision_requested', 'completed'))
    ),
    'recent_users', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(u))
      from (
        select
          p.id::text as user_id,
          coalesce(nullif(pg_catalog.btrim(p.full_name), ''), 'WorkBridge user') as full_name,
          coalesce(p.email, '') as email,
          ur.role,
          p.country_name,
          p.profile_completed,
          p.created_at
        from public.profiles p
        join public.user_roles ur on ur.user_id = p.id
        order by p.created_at desc
        limit 8
      ) u
    ), '[]'::jsonb),
    'recent_work_items', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(w))
      from (
        select
          t.id::text as task_id,
          t.title as task_title,
          t.category,
          t.status as task_status,
          q.status as quote_status,
          c.id::text as contract_id,
          c.status as contract_status,
          coalesce(c.currency, q.currency, t.currency) as currency,
          c.agreed_amount_minor,
          coalesce(nullif(pg_catalog.btrim(cp.full_name), ''), 'Client') as client_name,
          coalesce(nullif(pg_catalog.btrim(ep.full_name), ''), 'Engineer') as engineer_name,
          greatest(t.updated_at, coalesce(q.updated_at, t.updated_at), coalesce(c.updated_at, t.updated_at)) as updated_at
        from public.tasks t
        join public.profiles cp on cp.id = t.client_id
        join public.profiles ep on ep.id = t.engineer_id
        left join public.quotes q on q.task_id = t.id
        left join public.contracts c on c.task_id = t.id
        order by greatest(t.updated_at, coalesce(q.updated_at, t.updated_at), coalesce(c.updated_at, t.updated_at)) desc
        limit 10
      ) w
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$function$;

revoke all on function public.admin_get_dashboard_snapshot() from public, anon;
grant execute on function public.admin_get_dashboard_snapshot() to authenticated;

create or replace function public.admin_list_users(
  p_search text default null,
  p_role text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  user_id uuid,
  full_name text,
  email text,
  role text,
  country_name text,
  profile_completed boolean,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_search text := nullif(pg_catalog.btrim(coalesce(p_search, '')), '');
  v_filter_role text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_role, ''))), '');
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role from public.user_roles ur where ur.user_id = v_user_id;
  if v_role is distinct from 'admin' then
    raise exception 'Only administrators can list users' using errcode = '42501';
  end if;

  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'User page size must be between 1 and 100' using errcode = '22023';
  end if;
  if p_offset is null or p_offset < 0 then
    raise exception 'User offset cannot be negative' using errcode = '22023';
  end if;
  if v_filter_role is not null and v_filter_role not in ('client', 'engineer', 'admin') then
    raise exception 'Invalid user role filter' using errcode = '22023';
  end if;

  return query
  select
    p.id,
    coalesce(nullif(pg_catalog.btrim(p.full_name), ''), 'WorkBridge user')::text,
    coalesce(p.email, '')::text,
    ur.role::text,
    p.country_name::text,
    p.profile_completed,
    p.created_at
  from public.profiles p
  join public.user_roles ur on ur.user_id = p.id
  where (v_filter_role is null or ur.role = v_filter_role)
    and (
      v_search is null
      or p.full_name ilike '%' || v_search || '%'
      or p.email ilike '%' || v_search || '%'
      or coalesce(p.country_name, '') ilike '%' || v_search || '%'
    )
  order by p.created_at desc
  limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_list_users(text, text, integer, integer) from public, anon;
grant execute on function public.admin_list_users(text, text, integer, integer) to authenticated;

create or replace function public.admin_list_work_items(
  p_search text default null,
  p_status text default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  task_id uuid,
  task_title text,
  category text,
  task_status text,
  quote_status text,
  contract_id uuid,
  contract_status text,
  currency text,
  agreed_amount_minor bigint,
  client_name text,
  engineer_name text,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_search text := nullif(pg_catalog.btrim(coalesce(p_search, '')), '');
  v_status text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_status, ''))), '');
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role from public.user_roles ur where ur.user_id = v_user_id;
  if v_role is distinct from 'admin' then
    raise exception 'Only administrators can list marketplace work items' using errcode = '42501';
  end if;

  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'Work item page size must be between 1 and 100' using errcode = '22023';
  end if;
  if p_offset is null or p_offset < 0 then
    raise exception 'Work item offset cannot be negative' using errcode = '22023';
  end if;

  return query
  select
    t.id,
    t.title::text,
    t.category::text,
    t.status::text,
    q.status::text,
    c.id,
    c.status::text,
    coalesce(c.currency, q.currency, t.currency)::text,
    c.agreed_amount_minor,
    coalesce(nullif(pg_catalog.btrim(cp.full_name), ''), 'Client')::text,
    coalesce(nullif(pg_catalog.btrim(ep.full_name), ''), 'Engineer')::text,
    greatest(t.updated_at, coalesce(q.updated_at, t.updated_at), coalesce(c.updated_at, t.updated_at))
  from public.tasks t
  join public.profiles cp on cp.id = t.client_id
  join public.profiles ep on ep.id = t.engineer_id
  left join public.quotes q on q.task_id = t.id
  left join public.contracts c on c.task_id = t.id
  where (v_status is null or coalesce(c.status, t.status) = v_status)
    and (
      v_search is null
      or t.title ilike '%' || v_search || '%'
      or t.category ilike '%' || v_search || '%'
      or cp.full_name ilike '%' || v_search || '%'
      or ep.full_name ilike '%' || v_search || '%'
    )
  order by greatest(t.updated_at, coalesce(q.updated_at, t.updated_at), coalesce(c.updated_at, t.updated_at)) desc
  limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_list_work_items(text, text, integer, integer) from public, anon;
grant execute on function public.admin_list_work_items(text, text, integer, integer) to authenticated;

comment on function public.admin_get_dashboard_snapshot() is
  'Read-only Admin dashboard overview. Payment provider and transaction ledger are not integrated; contract states are not payment receipts.';
comment on function public.admin_list_users(text, text, integer, integer) is
  'Read-only Admin user directory. Does not suspend, delete, or modify accounts.';
comment on function public.admin_list_work_items(text, text, integer, integer) is
  'Read-only Admin marketplace task/quote/contract monitor. Does not modify work or payment state.';

notify pgrst, 'reload schema';

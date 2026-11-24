-- WorkBridge / permit_plans: secure, read-only Engineer project workspace.
-- Requires migrations 001, 002, 005, 007, 008, 009 and 010.
-- This migration creates no payment, escrow, delivery or payout state changes.

create or replace function public.get_my_engineer_projects(
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  contract_id uuid,
  task_id uuid,
  quote_id uuid,
  client_id uuid,
  client_name text,
  client_company_name text,
  client_country_name text,
  client_avatar_url text,
  task_title text,
  task_description text,
  task_category text,
  required_skills text[],
  deadline_at timestamptz,
  currency text,
  amount_minor bigint,
  delivery_days integer,
  scope_of_work text,
  included_revisions integer,
  notes text,
  commission_bps integer,
  platform_fee_minor bigint,
  engineer_net_minor bigint,
  contract_status text,
  confirmed_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_engineer_id uuid := auth.uid();
  v_role text;
begin
  if v_engineer_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_engineer_id;

  if v_role is distinct from 'engineer' then
    raise exception 'Only Engineers can view their project workspace'
      using errcode = '42501';
  end if;

  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'Project page size must be between 1 and 100'
      using errcode = '22023';
  end if;

  if p_offset is null or p_offset < 0 then
    raise exception 'Project offset cannot be negative'
      using errcode = '22023';
  end if;

  return query
  select
    c.id,
    c.task_id,
    c.quote_id,
    c.client_id,
    coalesce(
      nullif(pg_catalog.btrim(cp.company_name), ''),
      nullif(pg_catalog.btrim(pr.full_name), ''),
      'Marketplace client'
    )::text,
    nullif(pg_catalog.btrim(cp.company_name), '')::text,
    pr.country_name::text,
    pr.avatar_url::text,
    t.title::text,
    t.description::text,
    t.category::text,
    t.required_skills,
    t.deadline_at,
    c.currency::text,
    c.agreed_amount_minor,
    c.delivery_days,
    c.scope_of_work::text,
    c.included_revisions,
    c.notes::text,
    c.commission_bps,
    c.platform_fee_minor,
    c.engineer_net_minor,
    c.status::text,
    c.client_confirmed_at,
    c.created_at,
    c.updated_at
  from public.contracts c
  join public.tasks t on t.id = c.task_id
  join public.profiles pr on pr.id = c.client_id
  left join public.client_profiles cp on cp.user_id = c.client_id
  where c.engineer_id = v_engineer_id
  order by c.updated_at desc, c.created_at desc
  limit p_limit
  offset p_offset;
end;
$function$;

revoke all on function public.get_my_engineer_projects(integer, integer)
  from public, anon;
grant execute on function public.get_my_engineer_projects(integer, integer)
  to authenticated;

comment on function public.get_my_engineer_projects(integer, integer) is
  'Returns read-only contract projects for the signed-in Engineer only. Does not update contract, task, payment or payout state.';

notify pgrst, 'reload schema';

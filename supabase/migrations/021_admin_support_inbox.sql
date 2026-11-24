-- WorkBridge / permit_plans: Admin Support Inbox.
-- Requires migrations 001 and 020. The support response is stored in the
-- existing admin_note column and is visible to the ticket requester.

alter table public.support_requests
  add column if not exists priority text not null default 'normal';

do $migration$
begin
  if not exists (
    select 1
    from pg_catalog.pg_constraint
    where conname = 'support_requests_priority_check'
      and conrelid = 'public.support_requests'::pg_catalog.regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_priority_check
      check (priority in ('low', 'normal', 'high', 'urgent'));
  end if;
end;
$migration$;

create index if not exists support_requests_priority_created_idx
  on public.support_requests (priority, created_at desc);

grant update (priority) on table public.support_requests to authenticated;

create or replace function public.admin_list_support_requests(
  p_search text default null,
  p_status text default null,
  p_category text default null,
  p_priority text default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  id uuid,
  user_id uuid,
  account_role text,
  category text,
  subject text,
  message text,
  related_reference text,
  status text,
  priority text,
  admin_note text,
  created_at timestamptz,
  updated_at timestamptz,
  resolved_at timestamptz,
  requester_name text,
  requester_email text
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
  v_category text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_category, ''))), '');
  v_priority text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_priority, ''))), '');
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'admin' then
    raise exception 'Only administrators can view support requests'
      using errcode = '42501';
  end if;

  if p_limit is null or p_limit < 1 or p_limit > 200 then
    raise exception 'Support page size must be between 1 and 200'
      using errcode = '22023';
  end if;
  if p_offset is null or p_offset < 0 then
    raise exception 'Support page offset cannot be negative'
      using errcode = '22023';
  end if;
  if v_status is not null and v_status not in ('open', 'in_review', 'waiting_for_user', 'resolved', 'closed') then
    raise exception 'Invalid support status filter' using errcode = '22023';
  end if;
  if v_category is not null and v_category not in (
    'account_profile', 'tasks_invitations', 'quotes_contracts',
    'chat_delivery', 'payments_payouts', 'project_payment_dispute',
    'technical_issue', 'other'
  ) then
    raise exception 'Invalid support category filter' using errcode = '22023';
  end if;
  if v_priority is not null and v_priority not in ('low', 'normal', 'high', 'urgent') then
    raise exception 'Invalid support priority filter' using errcode = '22023';
  end if;

  return query
  select
    sr.id,
    sr.user_id,
    sr.account_role::text,
    sr.category::text,
    sr.subject::text,
    sr.message::text,
    sr.related_reference::text,
    sr.status::text,
    sr.priority::text,
    sr.admin_note::text,
    sr.created_at,
    sr.updated_at,
    sr.resolved_at,
    coalesce(nullif(pg_catalog.btrim(p.full_name), ''), 'WorkBridge user')::text,
    coalesce(p.email, '')::text
  from public.support_requests sr
  left join public.profiles p on p.id = sr.user_id
  where (v_status is null or sr.status = v_status)
    and (v_category is null or sr.category = v_category)
    and (v_priority is null or sr.priority = v_priority)
    and (
      v_search is null
      or sr.subject ilike '%' || v_search || '%'
      or sr.message ilike '%' || v_search || '%'
      or coalesce(p.full_name, '') ilike '%' || v_search || '%'
      or coalesce(p.email, '') ilike '%' || v_search || '%'
      or coalesce(sr.related_reference, '') ilike '%' || v_search || '%'
    )
  order by
    case sr.priority when 'urgent' then 0 when 'high' then 1 when 'normal' then 2 else 3 end,
    sr.created_at desc
  limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_list_support_requests(text, text, text, text, integer, integer)
  from public, anon;
grant execute on function public.admin_list_support_requests(text, text, text, text, integer, integer)
  to authenticated;

create or replace function public.admin_update_support_request(
  p_request_id uuid,
  p_status text,
  p_priority text,
  p_admin_note text default null
)
returns table (
  id uuid,
  status text,
  priority text,
  admin_note text,
  updated_at timestamptz,
  resolved_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_status text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_status, '')));
  v_priority text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_priority, '')));
  v_note text;
  v_updated_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'admin' then
    raise exception 'Only administrators can update support requests'
      using errcode = '42501';
  end if;

  if p_request_id is null then
    raise exception 'A support request is required' using errcode = '22023';
  end if;
  if v_status not in ('open', 'in_review', 'waiting_for_user', 'resolved', 'closed') then
    raise exception 'Choose a valid support status' using errcode = '22023';
  end if;
  if v_priority not in ('low', 'normal', 'high', 'urgent') then
    raise exception 'Choose a valid support priority' using errcode = '22023';
  end if;
  if p_admin_note is not null and pg_catalog.char_length(pg_catalog.btrim(p_admin_note)) > 3000 then
    raise exception 'Support response must be 3000 characters or fewer' using errcode = '22023';
  end if;

  v_note := case
    when p_admin_note is null then null
    else nullif(pg_catalog.btrim(p_admin_note), '')
  end;

  update public.support_requests sr
  set
    status = v_status,
    priority = v_priority,
    admin_note = case when p_admin_note is null then sr.admin_note else v_note end
  where sr.id = p_request_id
  returning sr.id into v_updated_id;

  if v_updated_id is null then
    raise exception 'Support request not found' using errcode = 'P0002';
  end if;

  return query
  select sr.id, sr.status::text, sr.priority::text, sr.admin_note::text, sr.updated_at, sr.resolved_at
  from public.support_requests sr
  where sr.id = v_updated_id;
end;
$function$;

revoke all on function public.admin_update_support_request(uuid, text, text, text)
  from public, anon;
grant execute on function public.admin_update_support_request(uuid, text, text, text)
  to authenticated;

notify pgrst, 'reload schema';

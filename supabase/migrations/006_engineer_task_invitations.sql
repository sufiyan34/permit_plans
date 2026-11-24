-- WorkBridge / permit_plans: Engineer invitation inbox and rejection action.
-- Requires migrations 001, 002, 004 and 005 to be applied first.
-- This migration does not create quotes or collect payments.

-- ---------------------------------------------------------------------------
-- Secure, limited read API for the signed-in Engineer's pending invitations.
-- The profiles/client_profiles tables are not made publicly readable.
-- ---------------------------------------------------------------------------
create or replace function public.get_my_task_invitations(
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  invitation_id uuid,
  task_id uuid,
  client_id uuid,
  client_name text,
  client_country_name text,
  client_avatar_url text,
  invitation_status text,
  sent_at timestamptz,
  task_title text,
  task_description text,
  task_category text,
  required_skills text[],
  currency text,
  budget_min_minor bigint,
  budget_max_minor bigint,
  deadline_at timestamptz,
  task_status text,
  attachment_count bigint
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
    raise exception 'Only Engineers can view task invitations' using errcode = '42501';
  end if;

  return query
  select
    ti.id as invitation_id,
    t.id as task_id,
    ti.client_id,
    coalesce(
      nullif(pg_catalog.btrim(cp.company_name), ''),
      nullif(pg_catalog.btrim(pr.full_name), ''),
      'Marketplace client'
    )::text as client_name,
    pr.country_name::text as client_country_name,
    pr.avatar_url::text as client_avatar_url,
    ti.status::text as invitation_status,
    ti.sent_at,
    t.title::text as task_title,
    t.description::text as task_description,
    t.category::text as task_category,
    t.required_skills,
    t.currency::text,
    t.budget_min_minor,
    t.budget_max_minor,
    t.deadline_at,
    t.status::text as task_status,
    (
      select pg_catalog.count(*)
      from public.task_attachments ta
      where ta.task_id = t.id
    ) as attachment_count
  from public.task_invitations ti
  join public.tasks t on t.id = ti.task_id
  join public.profiles pr on pr.id = ti.client_id
  left join public.client_profiles cp on cp.user_id = ti.client_id
  where ti.engineer_id = v_engineer_id
    and ti.status = 'pending'
    and t.status = 'invitation_pending'
  order by ti.sent_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100))
  offset greatest(coalesce(p_offset, 0), 0);
end;
$function$;

revoke all on function public.get_my_task_invitations(integer, integer)
  from public, anon;
grant execute on function public.get_my_task_invitations(integer, integer)
  to authenticated;

comment on function public.get_my_task_invitations(integer, integer) is
  'Returns only pending invitations addressed to the authenticated Engineer and limited Client/task display fields.';

-- ---------------------------------------------------------------------------
-- Secure rejection: only the invited Engineer may reject a pending invite.
-- Both updates happen atomically inside this function transaction.
-- ---------------------------------------------------------------------------
create or replace function public.reject_task_invitation(
  p_invitation_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_engineer_id uuid := auth.uid();
  v_role text;
  v_task_id uuid;
begin
  if v_engineer_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_engineer_id;

  if v_role is distinct from 'engineer' then
    raise exception 'Only Engineers can reject invitations' using errcode = '42501';
  end if;

  select ti.task_id into v_task_id
  from public.task_invitations ti
  where ti.id = p_invitation_id
    and ti.engineer_id = v_engineer_id
    and ti.status = 'pending'
  for update;

  if v_task_id is null then
    raise exception 'Invitation not found or no longer pending' using errcode = 'P0001';
  end if;

  update public.task_invitations
  set status = 'rejected',
      responded_at = pg_catalog.now()
  where id = p_invitation_id
    and engineer_id = v_engineer_id
    and status = 'pending';

  if not found then
    raise exception 'Invitation is no longer pending' using errcode = 'P0001';
  end if;

  update public.tasks
  set status = 'engineer_rejected',
      updated_at = pg_catalog.now()
  where id = v_task_id
    and engineer_id = v_engineer_id
    and status = 'invitation_pending';

  if not found then
    raise exception 'Task is no longer awaiting an Engineer response' using errcode = 'P0001';
  end if;

  return true;
end;
$function$;

revoke all on function public.reject_task_invitation(uuid)
  from public, anon;
grant execute on function public.reject_task_invitation(uuid)
  to authenticated;

comment on function public.reject_task_invitation(uuid) is
  'Allows only the invited Engineer to reject a pending invitation and moves the task to engineer_rejected.';

notify pgrst, 'reload schema';

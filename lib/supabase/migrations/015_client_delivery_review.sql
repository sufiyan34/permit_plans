-- WorkBridge / permit_plans: Client delivery review and final work decision.
-- Requires migrations 001, 002, 005, 010 and 013.
-- Approving completes the work record only. It DOES NOT release or pay funds.

create or replace function public.get_my_client_delivery_reviews(
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  delivery_id uuid,
  contract_id uuid,
  submission_number integer,
  message text,
  delivery_status text,
  created_at timestamptz,
  reviewed_at timestamptz,
  review_note text,
  task_title text,
  task_category text,
  currency text,
  agreed_amount_minor bigint,
  deadline_at timestamptz,
  engineer_id uuid,
  engineer_name text,
  engineer_avatar_url text,
  files jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'client' then
    raise exception 'Only Clients can review project deliveries' using errcode = '42501';
  end if;

  return query
  select
    d.id,
    d.contract_id,
    d.submission_number,
    d.message,
    d.status,
    d.created_at,
    d.reviewed_at,
    d.review_note,
    t.title::text,
    t.category::text,
    c.currency::text,
    c.agreed_amount_minor,
    t.deadline_at,
    c.engineer_id,
    coalesce(nullif(pg_catalog.btrim(ep.full_name), ''), 'Engineer')::text,
    ep.avatar_url,
    coalesce((
      select pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'id', f.id,
          'file_name', f.file_name,
          'mime_type', f.mime_type,
          'size_bytes', f.size_bytes,
          'storage_path', f.storage_path
        ) order by f.created_at asc
      )
      from public.project_delivery_files f
      where f.delivery_id = d.id
    ), '[]'::jsonb)
  from public.project_deliveries d
  join public.contracts c on c.id = d.contract_id
  join public.tasks t on t.id = c.task_id
  join public.profiles ep on ep.id = c.engineer_id
  where c.client_id = v_user_id
  order by d.created_at desc, d.submission_number desc
  limit greatest(1, least(coalesce(p_limit, 100), 100))
  offset greatest(coalesce(p_offset, 0), 0);
end;
$function$;

revoke all on function public.get_my_client_delivery_reviews(integer, integer)
  from public, anon;
grant execute on function public.get_my_client_delivery_reviews(integer, integer)
  to authenticated;

create or replace function public.review_project_delivery(
  p_delivery_id uuid,
  p_action text,
  p_review_note text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_contract_id uuid;
  v_action text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_action, '')));
  v_note text := nullif(pg_catalog.btrim(coalesce(p_review_note, '')), '');
  v_delivery_status text;
  v_contract_status text;
  v_next_status text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'client' then
    raise exception 'Only Clients can review project deliveries' using errcode = '42501';
  end if;

  if v_action not in ('approve', 'request_revision') then
    raise exception 'Choose approve or request_revision' using errcode = '22023';
  end if;

  if v_note is not null and pg_catalog.char_length(v_note) > 3000 then
    raise exception 'Review note must be 3000 characters or fewer' using errcode = '22023';
  end if;

  if v_action = 'request_revision'
     and (v_note is null or pg_catalog.char_length(v_note) < 10) then
    raise exception 'Revision note must contain at least 10 characters' using errcode = '22023';
  end if;

  -- Lock the Client-owned delivery and contract so duplicate or concurrent
  -- review actions cannot overwrite a decision.
  select d.contract_id, d.status, c.status
    into v_contract_id, v_delivery_status, v_contract_status
  from public.project_deliveries d
  join public.contracts c on c.id = d.contract_id
  where d.id = p_delivery_id
    and c.client_id = v_user_id
  for update of d, c;

  if v_contract_id is null then
    raise exception 'This delivery was not found in your projects' using errcode = '42501';
  end if;

  if v_delivery_status is distinct from 'submitted'
     or v_contract_status is distinct from 'submitted' then
    raise exception 'This delivery is no longer awaiting Client review' using errcode = 'P0001';
  end if;

  if v_action = 'approve' then
    v_next_status := 'completed';
    update public.project_deliveries
       set status = 'approved',
           reviewed_at = pg_catalog.now(),
           review_note = v_note
     where id = p_delivery_id;
  else
    v_next_status := 'revision_requested';
    update public.project_deliveries
       set status = 'revision_requested',
           reviewed_at = pg_catalog.now(),
           review_note = v_note
     where id = p_delivery_id;
  end if;

  update public.contracts
     set status = v_next_status,
         updated_at = pg_catalog.now()
   where id = v_contract_id;

  update public.tasks t
     set status = v_next_status,
         updated_at = pg_catalog.now()
  where t.id = (
    select c.task_id from public.contracts c where c.id = v_contract_id
  );

  return v_next_status;
end;
$function$;

revoke all on function public.review_project_delivery(uuid, text, text)
  from public, anon;
grant execute on function public.review_project_delivery(uuid, text, text)
  to authenticated;

-- Realtime lets the Client inbox detect new submissions and review decisions.
do $publication$
begin
  if exists (
    select 1 from pg_catalog.pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1 from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'project_deliveries'
  ) then
    execute 'alter publication supabase_realtime add table public.project_deliveries';
  end if;
end;
$publication$;

comment on function public.get_my_client_delivery_reviews(integer, integer) is
  'Returns delivery history only for contracts owned by the signed-in Client.';
comment on function public.review_project_delivery(uuid, text, text) is
  'Allows the owning Client to approve a submitted delivery or request revisions. Approval marks the work complete but does not release funds.';

notify pgrst, 'reload schema';

-- WorkBridge / permit_plans: Engineer work delivery and version history.
-- Requires migrations 001, 002, 010 and the project workspace contract table.
-- This records delivery submissions only. It does not approve work, release
-- payments, or change payout balances.

create table if not exists public.project_deliveries (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete restrict,
  engineer_id uuid not null references public.profiles(id) on delete restrict,
  submission_number integer not null,
  message text not null,
  status text not null default 'submitted',
  created_at timestamptz not null default pg_catalog.now(),
  reviewed_at timestamptz,
  review_note text,
  constraint project_deliveries_submission_number_positive
    check (submission_number > 0),
  constraint project_deliveries_message_length
    check (pg_catalog.char_length(pg_catalog.btrim(message)) between 20 and 5000),
  constraint project_deliveries_status_check
    check (status in ('submitted', 'revision_requested', 'approved', 'superseded')),
  constraint project_deliveries_contract_submission_unique
    unique (contract_id, submission_number)
);

create index if not exists project_deliveries_contract_created_idx
  on public.project_deliveries (contract_id, created_at desc);

create table if not exists public.project_delivery_files (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  delivery_id uuid not null references public.project_deliveries(id) on delete cascade,
  contract_id uuid not null references public.contracts(id) on delete restrict,
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null,
  created_at timestamptz not null default pg_catalog.now(),
  constraint project_delivery_files_name_length
    check (pg_catalog.char_length(pg_catalog.btrim(file_name)) between 1 and 255),
  constraint project_delivery_files_mime_length
    check (pg_catalog.char_length(pg_catalog.btrim(mime_type)) between 1 and 128),
  constraint project_delivery_files_size_check
    check (size_bytes between 1 and 26214400),
  constraint project_delivery_files_path_check
    check (storage_path like contract_id::text || '/' || uploaded_by::text || '/%')
);

create index if not exists project_delivery_files_delivery_idx
  on public.project_delivery_files (delivery_id, created_at asc);

alter table public.project_deliveries enable row level security;
alter table public.project_delivery_files enable row level security;
revoke all on table public.project_deliveries from anon, authenticated;
revoke all on table public.project_delivery_files from anon, authenticated;
grant select on table public.project_deliveries to authenticated;
grant select on table public.project_delivery_files to authenticated;

drop policy if exists "Contract parties can read project deliveries"
  on public.project_deliveries;
create policy "Contract parties can read project deliveries"
  on public.project_deliveries for select to authenticated
  using (
    exists (
      select 1 from public.contracts c
      where c.id = project_deliveries.contract_id
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

drop policy if exists "Contract parties can read delivery file metadata"
  on public.project_delivery_files;
create policy "Contract parties can read delivery file metadata"
  on public.project_delivery_files for select to authenticated
  using (
    exists (
      select 1 from public.contracts c
      where c.id = project_delivery_files.contract_id
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

-- Private bucket: <contract-id>/<engineer-id>/<random>_<safe-file-name>
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('project-deliveries', 'project-deliveries', false, 26214400, null)
on conflict (id) do update set
  public = false,
  file_size_limit = 26214400,
  allowed_mime_types = null;

drop policy if exists "Engineers upload their own project deliveries"
  on storage.objects;
create policy "Engineers upload their own project deliveries"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'project-deliveries'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1 from public.contracts c
      where c.id::text = (storage.foldername(name))[1]
        and c.engineer_id = (select auth.uid())
        and c.status in ('funded', 'in_progress', 'revision_requested')
    )
  );

drop policy if exists "Contract parties can read project delivery files"
  on storage.objects;
create policy "Contract parties can read project delivery files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'project-deliveries'
    and exists (
      select 1 from public.contracts c
      where c.id::text = (storage.foldername(name))[1]
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

drop policy if exists "Engineers can remove their own unsubmitted delivery uploads"
  on storage.objects;
create policy "Engineers can remove their own unsubmitted delivery uploads"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'project-deliveries'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1 from public.contracts c
      where c.id::text = (storage.foldername(name))[1]
        and c.engineer_id = (select auth.uid())
    )
  );

-- Engineer submits a new version. A previous revision-requested version is
-- retained as history and marked superseded. Contract status becomes submitted.
create or replace function public.submit_project_delivery(
  p_contract_id uuid,
  p_message text,
  p_files jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_contract public.contracts%rowtype;
  v_delivery_id uuid;
  v_submission_number integer;
  v_file jsonb;
  v_path text;
  v_file_name text;
  v_mime_type text;
  v_size bigint;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'engineer' then
    raise exception 'Only Engineers can submit project work' using errcode = '42501';
  end if;

  if p_message is null
     or pg_catalog.char_length(pg_catalog.btrim(p_message)) < 20
     or pg_catalog.char_length(pg_catalog.btrim(p_message)) > 5000 then
    raise exception 'Add a delivery note between 20 and 5000 characters' using errcode = '22023';
  end if;

  if p_files is null or pg_catalog.jsonb_typeof(p_files) <> 'array' then
    raise exception 'Delivery files must be supplied as a JSON array' using errcode = '22023';
  end if;
  if pg_catalog.jsonb_array_length(p_files) > 20 then
    raise exception 'Attach no more than 20 delivery files' using errcode = '22023';
  end if;

  select c.* into v_contract
  from public.contracts c
  where c.id = p_contract_id
    and c.engineer_id = v_user_id
  for update;

  if v_contract.id is null then
    raise exception 'This project does not belong to your account' using errcode = '42501';
  end if;

  if v_contract.status not in ('funded', 'in_progress', 'revision_requested') then
    raise exception 'Work can be submitted only after payment is confirmed and while the project is active or under revision' using errcode = 'P0001';
  end if;

  if v_contract.status = 'revision_requested' then
    update public.project_deliveries d
       set status = 'superseded'
     where d.contract_id = p_contract_id
       and d.status = 'revision_requested';
  end if;

  select coalesce(pg_catalog.max(d.submission_number), 0) + 1
    into v_submission_number
  from public.project_deliveries d
  where d.contract_id = p_contract_id;

  insert into public.project_deliveries (
    contract_id, engineer_id, submission_number, message, status
  ) values (
    p_contract_id, v_user_id, v_submission_number,
    pg_catalog.btrim(p_message), 'submitted'
  ) returning id into v_delivery_id;

  for v_file in select value from pg_catalog.jsonb_array_elements(p_files)
  loop
    v_path := nullif(v_file ->> 'storage_path', '');
    v_file_name := nullif(v_file ->> 'file_name', '');
    v_mime_type := nullif(v_file ->> 'mime_type', '');
    v_size := nullif(v_file ->> 'size_bytes', '')::bigint;

    if v_path is null or v_file_name is null or v_mime_type is null
       or v_size is null then
      raise exception 'A delivery file is missing required information' using errcode = '22023';
    end if;

    if pg_catalog.left(v_path, pg_catalog.length(p_contract_id::text || '/' || v_user_id::text || '/'))
       <> p_contract_id::text || '/' || v_user_id::text || '/'
       or pg_catalog.strpos(v_path, '..') > 0 then
      raise exception 'A delivery file path is invalid' using errcode = '22023';
    end if;

    if pg_catalog.char_length(v_file_name) > 255
       or v_size < 1 or v_size > 26214400 then
      raise exception 'A delivery file exceeds the allowed size or name length' using errcode = '22023';
    end if;

    if not (pg_catalog.lower(v_file_name) ~ '\.(pdf|doc|docx|xls|xlsx|ppt|pptx|png|jpe?g|webp|zip|csv|txt|dwg|dxf)$') then
      raise exception 'This delivery file type is not supported' using errcode = '22023';
    end if;

    if not exists (
      select 1 from storage.objects so
      where so.bucket_id = 'project-deliveries'
        and so.name = v_path
    ) then
      raise exception 'A delivery file upload could not be found' using errcode = 'P0001';
    end if;

    insert into public.project_delivery_files (
      delivery_id, contract_id, uploaded_by, storage_path,
      file_name, mime_type, size_bytes
    ) values (
      v_delivery_id, p_contract_id, v_user_id, v_path,
      v_file_name, v_mime_type, v_size
    );
  end loop;

  update public.contracts
     set status = 'submitted', updated_at = pg_catalog.now()
   where id = p_contract_id;

  return v_delivery_id;
end;
$function$;

revoke all on function public.submit_project_delivery(uuid, text, jsonb)
  from public, anon;
grant execute on function public.submit_project_delivery(uuid, text, jsonb)
  to authenticated;

-- Read the complete submission history for either party on a contract.
create or replace function public.get_my_project_deliveries(p_contract_id uuid)
returns table (
  delivery_id uuid,
  contract_id uuid,
  submission_number integer,
  message text,
  delivery_status text,
  created_at timestamptz,
  reviewed_at timestamptz,
  review_note text,
  files jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.contracts c
    where c.id = p_contract_id
      and (c.client_id = v_user_id or c.engineer_id = v_user_id)
  ) then
    raise exception 'You are not a party to this project' using errcode = '42501';
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
  where d.contract_id = p_contract_id
  order by d.submission_number desc;
end;
$function$;

revoke all on function public.get_my_project_deliveries(uuid) from public, anon;
grant execute on function public.get_my_project_deliveries(uuid) to authenticated;

comment on table public.project_deliveries is
  'Versioned Engineer delivery submissions. Submission does not approve work or release payment.';
comment on function public.submit_project_delivery(uuid, text, jsonb) is
  'Allows the assigned Engineer to submit delivery files only while a contract is funded, in progress or under revision. Sets contract status to submitted; does not release funds.';

notify pgrst, 'reload schema';

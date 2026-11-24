-- WorkBridge / permit_plans: direct task assignment to one selected engineer.
-- Requires migrations 001, 002 and 004 to have been applied first.
-- This migration DOES NOT collect or hold money. Payment is only requested
-- after the client and engineer agree on a quote in a later workflow.

-- ---------------------------------------------------------------------------
-- Core tables
-- ---------------------------------------------------------------------------
create table if not exists public.tasks (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  client_id uuid not null references public.profiles (id) on delete restrict,
  engineer_id uuid not null references public.profiles (id) on delete restrict,
  title text not null,
  description text not null,
  category text not null,
  required_skills text[] not null default '{}'::text[],
  currency text not null default 'USD',
  budget_min_minor bigint,
  budget_max_minor bigint,
  deadline_at timestamptz,
  status text not null default 'invitation_pending',
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  constraint tasks_title_length check (
    pg_catalog.length(pg_catalog.btrim(title)) between 8 and 120
  ),
  constraint tasks_description_length check (
    pg_catalog.length(pg_catalog.btrim(description)) between 30 and 10000
  ),
  constraint tasks_category_not_blank check (
    nullif(pg_catalog.btrim(category), '') is not null
  ),
  constraint tasks_currency_code check (currency ~ '^[A-Z]{3}$'),
  constraint tasks_min_budget_positive check (
    budget_min_minor is null or budget_min_minor > 0
  ),
  constraint tasks_max_budget_positive check (
    budget_max_minor is null or budget_max_minor > 0
  ),
  constraint tasks_budget_range check (
    budget_min_minor is null
    or budget_max_minor is null
    or budget_min_minor <= budget_max_minor
  ),
  constraint tasks_valid_status check (status in (
    'invitation_pending',
    'engineer_rejected',
    'quote_received',
    'negotiating',
    'awaiting_payment',
    'funded',
    'in_progress',
    'submitted',
    'revision_requested',
    'completed',
    'disputed',
    'cancelled',
    'refund_pending',
    'refunded'
  ))
);

create table if not exists public.task_invitations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  task_id uuid not null unique references public.tasks (id) on delete cascade,
  client_id uuid not null references public.profiles (id) on delete restrict,
  engineer_id uuid not null references public.profiles (id) on delete restrict,
  status text not null default 'pending',
  sent_at timestamptz not null default pg_catalog.now(),
  responded_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  constraint task_invitations_valid_status check (status in (
    'pending', 'rejected', 'quote_submitted', 'withdrawn', 'expired'
  )),
  constraint task_invitations_different_users check (client_id <> engineer_id)
);

create table if not exists public.task_attachments (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  task_id uuid not null references public.tasks (id) on delete cascade,
  uploaded_by uuid not null references public.profiles (id) on delete restrict,
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null,
  file_size_bytes bigint not null,
  created_at timestamptz not null default pg_catalog.now(),
  constraint task_attachments_file_name_not_blank check (
    nullif(pg_catalog.btrim(file_name), '') is not null
  ),
  constraint task_attachments_file_size check (
    file_size_bytes between 1 and 10485760
  )
);

create index if not exists tasks_client_created_idx
  on public.tasks (client_id, created_at desc);
create index if not exists tasks_engineer_status_created_idx
  on public.tasks (engineer_id, status, created_at desc);
create index if not exists task_invitations_engineer_status_idx
  on public.task_invitations (engineer_id, status, sent_at desc);
create index if not exists task_attachments_task_idx
  on public.task_attachments (task_id, created_at);

-- ---------------------------------------------------------------------------
-- RLS: users may read only tasks/invitations/attachments they participate in.
-- All creates are performed by the validated SECURITY DEFINER RPC below.
-- ---------------------------------------------------------------------------
alter table public.tasks enable row level security;
alter table public.task_invitations enable row level security;
alter table public.task_attachments enable row level security;

revoke all on table public.tasks from anon, authenticated;
revoke all on table public.task_invitations from anon, authenticated;
revoke all on table public.task_attachments from anon, authenticated;
grant select on table public.tasks to authenticated;
grant select on table public.task_invitations to authenticated;
grant select on table public.task_attachments to authenticated;

drop policy if exists "Task participants can read tasks" on public.tasks;
create policy "Task participants can read tasks"
  on public.tasks for select to authenticated
  using (
    client_id = (select auth.uid())
    or exists (
      select 1
      from public.task_invitations ti
      where ti.task_id = tasks.id
        and ti.engineer_id = (select auth.uid())
        and ti.status in ('pending', 'quote_submitted')
    )
  );

drop policy if exists "Task participants can read invitations" on public.task_invitations;
create policy "Task participants can read invitations"
  on public.task_invitations for select to authenticated
  using (
    client_id = (select auth.uid())
    or engineer_id = (select auth.uid())
  );

drop policy if exists "Task participants can read task attachments" on public.task_attachments;
create policy "Task participants can read task attachments"
  on public.task_attachments for select to authenticated
  using (
    exists (
      select 1
      from public.tasks t
      where t.id = task_attachments.task_id
        and (
          t.client_id = (select auth.uid())
          or exists (
            select 1 from public.task_invitations ti
            where ti.task_id = t.id
              and ti.engineer_id = (select auth.uid())
              and ti.status in ('pending', 'quote_submitted')
          )
        )
    )
  );

-- ---------------------------------------------------------------------------
-- Private Storage bucket for task reference files.
-- Object paths are: <client-user-uuid>/<timestamp>_<index>_<file-name>
-- ---------------------------------------------------------------------------
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'task-attachments',
  'task-attachments',
  false,
  10485760,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'image/png',
    'image/jpeg',
    'image/webp',
    'application/zip',
    'text/csv',
    'text/plain',
    'application/octet-stream'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = excluded.allowed_mime_types;

-- Clients can upload/delete only within their own UUID folder. They may read
-- their own files; the assigned engineer may read a file only after its
-- metadata is attached to a task invitation.
drop policy if exists "Clients upload own task reference files" on storage.objects;
create policy "Clients upload own task reference files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'task-attachments'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'client'
    )
  );

drop policy if exists "Task participants read task reference files" on storage.objects;
create policy "Task participants read task reference files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'task-attachments'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or exists (
        select 1
        from public.task_attachments ta
        join public.tasks t on t.id = ta.task_id
        where ta.storage_path = storage.objects.name
          and t.client_id = (select auth.uid())
      )
      or exists (
        select 1
        from public.task_attachments ta
        join public.tasks t on t.id = ta.task_id
        where ta.storage_path = storage.objects.name
          and exists (
            select 1 from public.task_invitations ti
            where ti.task_id = t.id
              and ti.engineer_id = (select auth.uid())
              and ti.status in ('pending', 'quote_submitted')
          )
      )
    )
  );

drop policy if exists "Clients delete own unsubmitted task files" on storage.objects;
create policy "Clients delete own unsubmitted task files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'task-attachments'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'client'
    )
  );

-- ---------------------------------------------------------------------------
-- Create task + invitation + attachment metadata atomically.
-- Storage objects are uploaded first by the client, then referenced here.
-- ---------------------------------------------------------------------------
create or replace function public.create_task_invitation(
  p_engineer_id uuid,
  p_title text,
  p_description text,
  p_category text,
  p_required_skills text[] default '{}'::text[],
  p_currency text default 'USD',
  p_budget_min_minor bigint default null,
  p_budget_max_minor bigint default null,
  p_deadline_at timestamptz default null,
  p_attachments jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid := auth.uid();
  v_client_role text;
  v_engineer_role text;
  v_engineer_availability text;
  v_engineer_complete boolean;
  v_task_id uuid := pg_catalog.gen_random_uuid();
  v_currency text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_currency, 'USD')));
  v_attachments jsonb := coalesce(p_attachments, '[]'::jsonb);
  v_item jsonb;
  v_storage_path text;
  v_file_name text;
  v_mime_type text;
  v_size_bytes bigint;
  v_skill text;
begin
  if v_client_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_client_role
  from public.user_roles ur
  where ur.user_id = v_client_id;

  if v_client_role is distinct from 'client' then
    raise exception 'Only Clients can assign tasks' using errcode = '42501';
  end if;

  if p_engineer_id is null or p_engineer_id = v_client_id then
    raise exception 'Choose a valid engineer' using errcode = '22023';
  end if;

  select ur.role, ep.availability, pr.profile_completed
    into v_engineer_role, v_engineer_availability, v_engineer_complete
  from public.user_roles ur
  join public.engineer_profiles ep on ep.user_id = ur.user_id
  join public.profiles pr on pr.id = ur.user_id
  where ur.user_id = p_engineer_id;

  if v_engineer_role is distinct from 'engineer' or v_engineer_complete is distinct from true then
    raise exception 'The selected engineer profile is not available' using errcode = '22023';
  end if;

  if v_engineer_availability not in ('available', 'limited') then
    raise exception 'This engineer is not accepting new assignments' using errcode = '22023';
  end if;

  if pg_catalog.length(pg_catalog.btrim(coalesce(p_title, ''))) not between 8 and 120 then
    raise exception 'Task title must contain between 8 and 120 characters' using errcode = '22023';
  end if;

  if pg_catalog.length(pg_catalog.btrim(coalesce(p_description, ''))) not between 30 and 10000 then
    raise exception 'Task description must contain between 30 and 10000 characters' using errcode = '22023';
  end if;

  if nullif(pg_catalog.btrim(coalesce(p_category, '')), '') is null then
    raise exception 'A task category is required' using errcode = '22023';
  end if;

  if v_currency !~ '^[A-Z]{3}$' then
    raise exception 'A valid three-letter currency code is required' using errcode = '22023';
  end if;

  if p_budget_min_minor is not null and p_budget_min_minor <= 0 then
    raise exception 'Minimum budget must be greater than zero' using errcode = '22023';
  end if;
  if p_budget_max_minor is not null and p_budget_max_minor <= 0 then
    raise exception 'Maximum budget must be greater than zero' using errcode = '22023';
  end if;
  if p_budget_min_minor is not null and p_budget_max_minor is not null
     and p_budget_min_minor > p_budget_max_minor then
    raise exception 'Minimum budget cannot be greater than maximum budget' using errcode = '22023';
  end if;

  if p_deadline_at is not null and p_deadline_at <= pg_catalog.now() then
    raise exception 'Deadline must be in the future' using errcode = '22023';
  end if;

  if coalesce(pg_catalog.cardinality(p_required_skills), 0) > 12 then
    raise exception 'You can add up to 12 required skills' using errcode = '22023';
  end if;
  foreach v_skill in array coalesce(p_required_skills, '{}'::text[]) loop
    if nullif(pg_catalog.btrim(v_skill), '') is null or pg_catalog.length(pg_catalog.btrim(v_skill)) > 40 then
      raise exception 'Each required skill must contain between 1 and 40 characters' using errcode = '22023';
    end if;
  end loop;

  if pg_catalog.jsonb_typeof(v_attachments) is distinct from 'array' then
    raise exception 'Attachments must be a list' using errcode = '22023';
  end if;
  if pg_catalog.jsonb_array_length(v_attachments) > 5 then
    raise exception 'You can attach up to 5 files' using errcode = '22023';
  end if;

  for v_item in select value from pg_catalog.jsonb_array_elements(v_attachments) as x(value)
  loop
    v_storage_path := coalesce(v_item ->> 'storage_path', '');
    v_file_name := coalesce(v_item ->> 'file_name', '');
    v_mime_type := coalesce(v_item ->> 'mime_type', '');
    if coalesce(v_item ->> 'size_bytes', '') !~ '^[0-9]+$' then
      raise exception 'Attachment size is invalid' using errcode = '22023';
    end if;
    v_size_bytes := (v_item ->> 'size_bytes')::bigint;

    if pg_catalog.left(v_storage_path, pg_catalog.length(v_client_id::text) + 1) <> (v_client_id::text || '/') then
      raise exception 'Attachment path does not belong to this Client' using errcode = '42501';
    end if;
    if nullif(pg_catalog.btrim(v_file_name), '') is null
       or nullif(pg_catalog.btrim(v_mime_type), '') is null
       or v_size_bytes < 1 or v_size_bytes > 10485760 then
      raise exception 'Attachment details are invalid' using errcode = '22023';
    end if;
    if not exists (
      select 1 from storage.objects so
      where so.bucket_id = 'task-attachments'
        and so.name = v_storage_path
    ) then
      raise exception 'An attachment is missing from private task storage' using errcode = '22023';
    end if;
  end loop;

  insert into public.tasks (
    id, client_id, engineer_id, title, description, category,
    required_skills, currency, budget_min_minor, budget_max_minor,
    deadline_at, status
  ) values (
    v_task_id, v_client_id, p_engineer_id,
    pg_catalog.btrim(p_title), pg_catalog.btrim(p_description),
    pg_catalog.btrim(p_category), coalesce(p_required_skills, '{}'::text[]),
    v_currency, p_budget_min_minor, p_budget_max_minor,
    p_deadline_at, 'invitation_pending'
  );

  insert into public.task_invitations (task_id, client_id, engineer_id, status)
  values (v_task_id, v_client_id, p_engineer_id, 'pending');

  for v_item in select value from pg_catalog.jsonb_array_elements(v_attachments) as x(value)
  loop
    insert into public.task_attachments (
      task_id, uploaded_by, storage_path, file_name, mime_type, file_size_bytes
    ) values (
      v_task_id,
      v_client_id,
      v_item ->> 'storage_path',
      v_item ->> 'file_name',
      v_item ->> 'mime_type',
      (v_item ->> 'size_bytes')::bigint
    );
  end loop;

  return v_task_id;
end;
$function$;

revoke all on function public.create_task_invitation(
  uuid, text, text, text, text[], text, bigint, bigint, timestamptz, jsonb
) from public, anon;
grant execute on function public.create_task_invitation(
  uuid, text, text, text, text[], text, bigint, bigint, timestamptz, jsonb
) to authenticated;

comment on function public.create_task_invitation(
  uuid, text, text, text, text[], text, bigint, bigint, timestamptz, jsonb
) is 'Creates one Client task and a pending direct invitation for one selected Engineer. Does not collect payment.';

notify pgrst, 'reload schema';

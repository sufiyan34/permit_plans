-- WorkBridge / permit_plans: private project chat for confirmed contracts.
-- Requires migrations 001, 002, 005 and 010 (and the contracts table).
-- Messages are immutable. Only the recipient can set read_at.
-- Attachments are private Storage objects and are limited to contract parties.

create table if not exists public.project_messages (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete restrict,
  sender_id uuid not null references public.profiles(id) on delete restrict,
  body text not null default '',
  attachment_path text,
  attachment_name text,
  attachment_mime_type text,
  attachment_size_bytes bigint,
  created_at timestamptz not null default pg_catalog.now(),
  read_at timestamptz,
  constraint project_messages_body_length check (
    pg_catalog.char_length(pg_catalog.btrim(body)) <= 4000
  ),
  constraint project_messages_content_required check (
    pg_catalog.length(pg_catalog.btrim(body)) > 0 or attachment_path is not null
  ),
  constraint project_messages_attachment_metadata check (
    (attachment_path is null
      and attachment_name is null
      and attachment_mime_type is null
      and attachment_size_bytes is null)
    or
    (attachment_path is not null
      and attachment_name is not null
      and attachment_mime_type is not null
      and attachment_size_bytes between 1 and 10485760
      and attachment_path like contract_id::text || '/' || sender_id::text || '/%')
  )
);

create index if not exists project_messages_contract_created_idx
  on public.project_messages (contract_id, created_at asc, id asc);
create index if not exists project_messages_unread_idx
  on public.project_messages (contract_id, sender_id, read_at)
  where read_at is null;

alter table public.project_messages enable row level security;
revoke all on table public.project_messages from anon, authenticated;
grant select on table public.project_messages to authenticated;
grant insert (contract_id, sender_id, body, attachment_path, attachment_name,
              attachment_mime_type, attachment_size_bytes)
  on table public.project_messages to authenticated;
grant update (read_at) on table public.project_messages to authenticated;

drop policy if exists "Contract parties can read project messages"
  on public.project_messages;
create policy "Contract parties can read project messages"
  on public.project_messages for select to authenticated
  using (
    exists (
      select 1
      from public.contracts c
      where c.id = project_messages.contract_id
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

drop policy if exists "Contract parties can send project messages"
  on public.project_messages;
create policy "Contract parties can send project messages"
  on public.project_messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1
      from public.contracts c
      where c.id = project_messages.contract_id
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

drop policy if exists "Recipients can mark project messages read"
  on public.project_messages;
create policy "Recipients can mark project messages read"
  on public.project_messages for update to authenticated
  using (
    sender_id <> (select auth.uid())
    and read_at is null
    and exists (
      select 1
      from public.contracts c
      where c.id = project_messages.contract_id
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  )
  with check (
    sender_id <> (select auth.uid())
    and read_at is not null
    and exists (
      select 1
      from public.contracts c
      where c.id = project_messages.contract_id
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

-- Private project-chat file storage. Paths are:
-- <contract-uuid>/<sender-uuid>/<random-prefix>_<safe-file-name>
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'project-chat-attachments',
  'project-chat-attachments',
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
    'text/plain'
  ]::text[]
)
on conflict (id) do update set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Project participants upload their own chat files"
  on storage.objects;
create policy "Project participants upload their own chat files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'project-chat-attachments'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1
      from public.contracts c
      where c.id::text = (storage.foldername(name))[1]
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

drop policy if exists "Project participants read chat files"
  on storage.objects;
create policy "Project participants read chat files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'project-chat-attachments'
    and exists (
      select 1
      from public.contracts c
      where c.id::text = (storage.foldername(name))[1]
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

drop policy if exists "Senders can remove orphaned chat uploads"
  on storage.objects;
create policy "Senders can remove orphaned chat uploads"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'project-chat-attachments'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1
      from public.contracts c
      where c.id::text = (storage.foldername(name))[1]
        and (c.client_id = (select auth.uid())
          or c.engineer_id = (select auth.uid()))
    )
  );

-- Return only conversations in which the signed-in account is one of the
-- immutable contract parties. This includes the opposite party's safe display
-- name and avatar, but never email, phone, billing or payout data.
create or replace function public.get_my_project_chats(
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  contract_id uuid,
  task_id uuid,
  task_title text,
  contract_status text,
  partner_id uuid,
  partner_name text,
  partner_avatar_url text,
  partner_role text,
  last_message_preview text,
  last_attachment_name text,
  last_message_at timestamptz,
  unread_count integer,
  created_at timestamptz
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

  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'Chat page size must be between 1 and 100'
      using errcode = '22023';
  end if;

  if p_offset is null or p_offset < 0 then
    raise exception 'Chat offset cannot be negative' using errcode = '22023';
  end if;

  return query
  select
    c.id,
    c.task_id,
    t.title::text,
    c.status::text,
    case when c.client_id = v_user_id then c.engineer_id else c.client_id end,
    case
      when c.client_id = v_user_id then
        coalesce(nullif(pg_catalog.btrim(engineer_profile.full_name), ''), 'Engineer')
      else
        coalesce(
          nullif(pg_catalog.btrim(client_profile_data.company_name), ''),
          nullif(pg_catalog.btrim(client_profile.full_name), ''),
          'Client'
        )
    end::text,
    case when c.client_id = v_user_id
      then engineer_profile.avatar_url else client_profile.avatar_url end::text,
    case when c.client_id = v_user_id then 'engineer' else 'client' end::text,
    coalesce(
      nullif(pg_catalog.left(pg_catalog.btrim(latest_message.body), 120), ''),
      case when latest_message.attachment_name is not null
        then 'Attachment' else null end
    )::text,
    latest_message.attachment_name::text,
    coalesce(latest_message.created_at, c.created_at),
    (
      select pg_catalog.count(*)::integer
      from public.project_messages unread_message
      where unread_message.contract_id = c.id
        and unread_message.sender_id <> v_user_id
        and unread_message.read_at is null
    ),
    c.created_at
  from public.contracts c
  join public.tasks t on t.id = c.task_id
  join public.profiles engineer_profile on engineer_profile.id = c.engineer_id
  join public.profiles client_profile on client_profile.id = c.client_id
  left join public.client_profiles client_profile_data
    on client_profile_data.user_id = c.client_id
  left join lateral (
    select pm.body, pm.attachment_name, pm.created_at
    from public.project_messages pm
    where pm.contract_id = c.id
    order by pm.created_at desc, pm.id desc
    limit 1
  ) latest_message on true
  where c.client_id = v_user_id or c.engineer_id = v_user_id
  order by coalesce(latest_message.created_at, c.created_at) desc,
           c.created_at desc
  limit p_limit
  offset p_offset;
end;
$function$;

revoke all on function public.get_my_project_chats(integer, integer)
  from public, anon;
grant execute on function public.get_my_project_chats(integer, integer)
  to authenticated;

-- A receiver can mark only messages in their own contract conversation read.
create or replace function public.mark_project_messages_read(
  p_contract_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_updated_count integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.contracts c
    where c.id = p_contract_id
      and (c.client_id = v_user_id or c.engineer_id = v_user_id)
  ) then
    raise exception 'You do not have access to this project chat'
      using errcode = '42501';
  end if;

  update public.project_messages pm
  set read_at = pg_catalog.now()
  where pm.contract_id = p_contract_id
    and pm.sender_id <> v_user_id
    and pm.read_at is null;

  get diagnostics v_updated_count = row_count;
  return v_updated_count;
end;
$function$;

revoke all on function public.mark_project_messages_read(uuid)
  from public, anon;
grant execute on function public.mark_project_messages_read(uuid)
  to authenticated;

comment on table public.project_messages is
  'Private, append-only Client/Engineer chat attached to a confirmed WorkBridge contract. Attachments are private Storage objects.';
comment on function public.get_my_project_chats(integer, integer) is
  'Returns only conversations belonging to the signed-in contract party, with safe partner display details and unread counts.';
comment on function public.mark_project_messages_read(uuid) is
  'Marks inbound messages read for a contract only when the caller is one of its parties.';

-- Supabase Realtime is disabled for new tables unless replication is enabled.
-- Add the table only when the standard publication is present and it is not
-- already registered, so this migration remains safe to retry.
alter table public.project_messages replica identity full;
do $publication$
begin
  if exists (
    select 1 from pg_catalog.pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1 from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'project_messages'
  ) then
    alter publication supabase_realtime add table public.project_messages;
  end if;
end;
$publication$;

notify pgrst, 'reload schema';

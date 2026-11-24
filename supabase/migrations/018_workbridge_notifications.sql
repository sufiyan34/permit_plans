-- WorkBridge / permit_plans: in-app notifications for marketplace activity.
-- Requires migrations 001, 005, 007, 010, 012 and 013 to be applied first.
-- This migration creates in-app notification records only. It does not send
-- email, SMS, FCM/APNs push notifications, or perform payment actions.

create table if not exists public.notifications (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  notification_type text not null,
  title text not null,
  body text not null default '',
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  constraint notifications_type_check check (notification_type in (
    'task_invitation_received',
    'task_invitation_rejected',
    'quote_received',
    'client_counteroffer_received',
    'engineer_counteroffer_received',
    'quote_accepted',
    'quote_rejected',
    'contract_confirmed',
    'project_message_received',
    'delivery_submitted',
    'revision_requested',
    'delivery_approved'
  )),
  constraint notifications_title_length check (
    pg_catalog.char_length(pg_catalog.btrim(title)) between 1 and 160
  ),
  constraint notifications_body_length check (
    pg_catalog.char_length(body) <= 500
  ),
  constraint notifications_read_state_consistent check (
    (is_read and read_at is not null) or (not is_read and read_at is null)
  )
);

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);
create index if not exists notifications_recipient_unread_idx
  on public.notifications (recipient_id, created_at desc)
  where is_read = false;

alter table public.notifications enable row level security;
revoke all on table public.notifications from anon, authenticated;
grant select on table public.notifications to authenticated;
grant update (is_read, read_at) on table public.notifications to authenticated;

drop policy if exists "Users can read their own notifications"
  on public.notifications;
create policy "Users can read their own notifications"
  on public.notifications for select to authenticated
  using (recipient_id = (select auth.uid()));

drop policy if exists "Users can update read state of their notifications"
  on public.notifications;
create policy "Users can update read state of their notifications"
  on public.notifications for update to authenticated
  using (recipient_id = (select auth.uid()))
  with check (recipient_id = (select auth.uid()));

-- Only database triggers can create notifications. The function is not
-- executable by app users and never trusts a recipient supplied by the client.
create or replace function public.emit_workbridge_notification(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_notification_type text,
  p_title text,
  p_body text,
  p_entity_type text default null,
  p_entity_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if p_recipient_id is null or p_recipient_id = p_actor_id then
    return;
  end if;

  insert into public.notifications (
    recipient_id, actor_id, notification_type, title, body,
    entity_type, entity_id, metadata
  ) values (
    p_recipient_id,
    p_actor_id,
    p_notification_type,
    pg_catalog.left(pg_catalog.btrim(coalesce(p_title, 'WorkBridge update')), 160),
    pg_catalog.left(coalesce(p_body, ''), 500),
    p_entity_type,
    p_entity_id,
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$function$;
revoke all on function public.emit_workbridge_notification(
  uuid, uuid, text, text, text, text, uuid, jsonb
) from public, anon, authenticated;

-- 1. A Client assigns a task to an Engineer.
create or replace function public.notify_task_invitation_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_title text;
begin
  select t.title into v_title
  from public.tasks t
  where t.id = new.task_id;

  perform public.emit_workbridge_notification(
    new.engineer_id,
    new.client_id,
    'task_invitation_received',
    'New task invitation',
    coalesce(v_title, 'A client assigned a task to you.'),
    'task',
    new.task_id,
    pg_catalog.jsonb_build_object(
      'task_id', new.task_id,
      'invitation_id', new.id
    )
  );
  return new;
end;
$function$;
revoke all on function public.notify_task_invitation_created()
  from public, anon, authenticated;

drop trigger if exists workbridge_task_invitation_created
  on public.task_invitations;
create trigger workbridge_task_invitation_created
  after insert on public.task_invitations
  for each row execute function public.notify_task_invitation_created();

-- 2. Notify the Client if the invited Engineer declines the task.
create or replace function public.notify_task_invitation_rejected()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_title text;
begin
  if new.status = 'rejected' and old.status is distinct from new.status then
    select t.title into v_title
    from public.tasks t
    where t.id = new.task_id;

    perform public.emit_workbridge_notification(
      new.client_id,
      new.engineer_id,
      'task_invitation_rejected',
      'Engineer declined your invitation',
      coalesce(v_title, 'The assigned Engineer declined your task.'),
      'task',
      new.task_id,
      pg_catalog.jsonb_build_object('task_id', new.task_id, 'invitation_id', new.id)
    );
  end if;
  return new;
end;
$function$;
revoke all on function public.notify_task_invitation_rejected()
  from public, anon, authenticated;

drop trigger if exists workbridge_task_invitation_rejected
  on public.task_invitations;
create trigger workbridge_task_invitation_rejected
  after update of status on public.task_invitations
  for each row execute function public.notify_task_invitation_rejected();

-- 3. A quote revision is an initial Engineer quote or a counteroffer by either party.
create or replace function public.notify_quote_revision_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid;
  v_engineer_id uuid;
  v_task_id uuid;
  v_task_title text;
  v_recipient_id uuid;
  v_type text;
  v_title text;
  v_body text;
begin
  select q.client_id, q.engineer_id, q.task_id, t.title
    into v_client_id, v_engineer_id, v_task_id, v_task_title
  from public.quotes q
  join public.tasks t on t.id = q.task_id
  where q.id = new.quote_id;

  if not found then return new; end if;

  if new.action = 'initial' then
    v_recipient_id := v_client_id;
    v_type := 'quote_received';
    v_title := 'New quote received';
    v_body := 'An Engineer sent a quote for ' || coalesce(v_task_title, 'your task') || '.';
  elsif new.action = 'client_counteroffer' then
    v_recipient_id := v_engineer_id;
    v_type := 'client_counteroffer_received';
    v_title := 'Client sent a counteroffer';
    v_body := 'A Client proposed revised terms for ' || coalesce(v_task_title, 'the task') || '.';
  elsif new.action = 'engineer_counteroffer' then
    v_recipient_id := v_client_id;
    v_type := 'engineer_counteroffer_received';
    v_title := 'Engineer sent a counteroffer';
    v_body := 'The Engineer proposed revised terms for ' || coalesce(v_task_title, 'your task') || '.';
  else
    return new;
  end if;

  perform public.emit_workbridge_notification(
    v_recipient_id,
    new.proposed_by,
    v_type,
    v_title,
    v_body,
    'quote',
    new.quote_id,
    pg_catalog.jsonb_build_object(
      'quote_id', new.quote_id,
      'task_id', v_task_id,
      'revision_id', new.id
    )
  );
  return new;
end;
$function$;
revoke all on function public.notify_quote_revision_created()
  from public, anon, authenticated;

drop trigger if exists workbridge_quote_revision_created
  on public.quote_revisions;
create trigger workbridge_quote_revision_created
  after insert on public.quote_revisions
  for each row execute function public.notify_quote_revision_created();

-- 4. Let the Engineer know when the Client accepts or rejects the quote.
create or replace function public.notify_quote_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_task_title text;
begin
  if old.status is distinct from new.status
     and new.status in ('accepted', 'rejected') then
    select t.title into v_task_title
    from public.tasks t
    where t.id = new.task_id;

    perform public.emit_workbridge_notification(
      new.engineer_id,
      new.client_id,
      case when new.status = 'accepted' then 'quote_accepted' else 'quote_rejected' end,
      case when new.status = 'accepted' then 'Quote accepted' else 'Quote declined' end,
      case when new.status = 'accepted'
        then 'The Client accepted your quote for ' || coalesce(v_task_title, 'the task') || '.'
        else 'The Client declined your quote for ' || coalesce(v_task_title, 'the task') || '.'
      end,
      'quote',
      new.id,
      pg_catalog.jsonb_build_object('quote_id', new.id, 'task_id', new.task_id)
    );
  end if;
  return new;
end;
$function$;
revoke all on function public.notify_quote_decision()
  from public, anon, authenticated;

drop trigger if exists workbridge_quote_decision on public.quotes;
create trigger workbridge_quote_decision
  after update of status on public.quotes
  for each row execute function public.notify_quote_decision();

-- 5. Once a Client confirms the agreed contract, notify the Engineer. This is
-- a contract confirmation only; the payment provider must still confirm funds.
create or replace function public.notify_contract_confirmed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_task_title text;
begin
  select t.title into v_task_title
  from public.tasks t
  where t.id = new.task_id;

  perform public.emit_workbridge_notification(
    new.engineer_id,
    new.client_id,
    'contract_confirmed',
    'Contract confirmed',
    'The Client confirmed the agreed terms for ' || coalesce(v_task_title, 'your project') || '. Payment confirmation is still required before work starts.',
    'contract',
    new.id,
    pg_catalog.jsonb_build_object('contract_id', new.id, 'task_id', new.task_id)
  );
  return new;
end;
$function$;
revoke all on function public.notify_contract_confirmed()
  from public, anon, authenticated;

drop trigger if exists workbridge_contract_confirmed on public.contracts;
create trigger workbridge_contract_confirmed
  after insert on public.contracts
  for each row execute function public.notify_contract_confirmed();

-- 6. Notify the other party when a Project Chat message is created.
create or replace function public.notify_project_message_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid;
  v_engineer_id uuid;
  v_task_id uuid;
  v_task_title text;
  v_recipient_id uuid;
  v_preview text;
begin
  select c.client_id, c.engineer_id, c.task_id, t.title
    into v_client_id, v_engineer_id, v_task_id, v_task_title
  from public.contracts c
  join public.tasks t on t.id = c.task_id
  where c.id = new.contract_id;

  if not found then return new; end if;
  if new.sender_id = v_client_id then
    v_recipient_id := v_engineer_id;
  elsif new.sender_id = v_engineer_id then
    v_recipient_id := v_client_id;
  else
    return new;
  end if;

  v_preview := case
    when pg_catalog.length(pg_catalog.btrim(coalesce(new.body, ''))) > 0
      then pg_catalog.left(pg_catalog.btrim(new.body), 150)
    else 'Sent an attachment.'
  end;

  perform public.emit_workbridge_notification(
    v_recipient_id,
    new.sender_id,
    'project_message_received',
    'New project message',
    coalesce(v_task_title, 'Project') || ': ' || v_preview,
    'contract',
    new.contract_id,
    pg_catalog.jsonb_build_object(
      'contract_id', new.contract_id,
      'task_id', v_task_id,
      'message_id', new.id
    )
  );
  return new;
end;
$function$;
revoke all on function public.notify_project_message_created()
  from public, anon, authenticated;

drop trigger if exists workbridge_project_message_created
  on public.project_messages;
create trigger workbridge_project_message_created
  after insert on public.project_messages
  for each row execute function public.notify_project_message_created();

-- 7. Notify the Client when the Engineer submits a delivery.
create or replace function public.notify_project_delivery_submitted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid;
  v_task_id uuid;
  v_task_title text;
begin
  select c.client_id, c.task_id, t.title
    into v_client_id, v_task_id, v_task_title
  from public.contracts c
  join public.tasks t on t.id = c.task_id
  where c.id = new.contract_id;

  if not found then return new; end if;

  perform public.emit_workbridge_notification(
    v_client_id,
    new.engineer_id,
    'delivery_submitted',
    'Work submitted for review',
    coalesce(v_task_title, 'Your project') || ' · Delivery #' || new.submission_number::text || ' is ready for review.',
    'delivery',
    new.id,
    pg_catalog.jsonb_build_object(
      'delivery_id', new.id,
      'contract_id', new.contract_id,
      'task_id', v_task_id,
      'submission_number', new.submission_number
    )
  );
  return new;
end;
$function$;
revoke all on function public.notify_project_delivery_submitted()
  from public, anon, authenticated;

drop trigger if exists workbridge_project_delivery_submitted
  on public.project_deliveries;
create trigger workbridge_project_delivery_submitted
  after insert on public.project_deliveries
  for each row execute function public.notify_project_delivery_submitted();

-- 8. Notify the Engineer when the Client requests revisions or approves work.
create or replace function public.notify_project_delivery_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid;
  v_task_id uuid;
  v_task_title text;
  v_type text;
  v_title text;
  v_body text;
begin
  if old.status is not distinct from new.status then return new; end if;
  if new.status not in ('revision_requested', 'approved') then return new; end if;

  select c.client_id, c.task_id, t.title
    into v_client_id, v_task_id, v_task_title
  from public.contracts c
  join public.tasks t on t.id = c.task_id
  where c.id = new.contract_id;

  if not found then return new; end if;

  if new.status = 'revision_requested' then
    v_type := 'revision_requested';
    v_title := 'Client requested revisions';
    v_body := coalesce(v_task_title, 'Your project') || ': ' ||
      coalesce(nullif(pg_catalog.btrim(new.review_note), ''), 'The Client requested changes to the delivery.');
  else
    v_type := 'delivery_approved';
    v_title := 'Delivery approved';
    v_body := coalesce(v_task_title, 'Your project') || ' was approved by the Client. The work is marked complete.';
  end if;

  perform public.emit_workbridge_notification(
    new.engineer_id,
    v_client_id,
    v_type,
    v_title,
    v_body,
    'delivery',
    new.id,
    pg_catalog.jsonb_build_object(
      'delivery_id', new.id,
      'contract_id', new.contract_id,
      'task_id', v_task_id,
      'submission_number', new.submission_number
    )
  );
  return new;
end;
$function$;
revoke all on function public.notify_project_delivery_decision()
  from public, anon, authenticated;

drop trigger if exists workbridge_project_delivery_decision
  on public.project_deliveries;
create trigger workbridge_project_delivery_decision
  after update of status on public.project_deliveries
  for each row execute function public.notify_project_delivery_decision();

-- Realtime updates the signed-in user's in-app inbox without manual refresh.
do $publication$
begin
  if exists (
    select 1 from pg_catalog.pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1 from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    execute 'alter publication supabase_realtime add table public.notifications';
  end if;
end;
$publication$;

comment on table public.notifications is
  'Private in-app notification inbox. Rows are created by database event triggers; clients may only read and update their own read state.';
comment on function public.emit_workbridge_notification(uuid, uuid, text, text, text, text, uuid, jsonb) is
  'Internal trigger helper. Not executable by authenticated app users.';

notify pgrst, 'reload schema';

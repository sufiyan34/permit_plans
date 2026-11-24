-- WorkBridge / permit_plans: per-user notification preferences.
-- Requires migration 018_workbridge_notifications.sql to be applied first.
-- Email and push settings are stored for future delivery integrations. This
-- migration does not send email, FCM, APNs, SMS, or any external notification.

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  in_app_enabled boolean not null default true,
  email_enabled boolean not null default false,
  push_enabled boolean not null default false,
  task_updates boolean not null default true,
  quote_updates boolean not null default true,
  message_updates boolean not null default true,
  delivery_updates boolean not null default true,
  project_updates boolean not null default true,
  updated_at timestamptz not null default pg_catalog.now()
);

comment on table public.notification_preferences is
  'Per-user WorkBridge notification choices. Email and push flags are stored preferences only until delivery providers are configured.';

create or replace function public.set_notification_preferences_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$function$;
revoke all on function public.set_notification_preferences_updated_at()
  from public, anon, authenticated;

drop trigger if exists notification_preferences_set_updated_at
  on public.notification_preferences;
create trigger notification_preferences_set_updated_at
  before update on public.notification_preferences
  for each row execute function public.set_notification_preferences_updated_at();

alter table public.notification_preferences enable row level security;
revoke all on table public.notification_preferences from anon, authenticated;
grant select, insert, update on table public.notification_preferences to authenticated;

drop policy if exists "Users can read their own notification preferences"
  on public.notification_preferences;
create policy "Users can read their own notification preferences"
  on public.notification_preferences for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can create their own notification preferences"
  on public.notification_preferences;
create policy "Users can create their own notification preferences"
  on public.notification_preferences for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "Users can update their own notification preferences"
  on public.notification_preferences;
create policy "Users can update their own notification preferences"
  on public.notification_preferences for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Keep migration 018's trigger functions intact, but make their shared helper
-- honor the recipient's in-app master switch and selected event categories.
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
declare
  v_in_app_enabled boolean := true;
  v_task_updates boolean := true;
  v_quote_updates boolean := true;
  v_message_updates boolean := true;
  v_delivery_updates boolean := true;
  v_project_updates boolean := true;
  v_category_enabled boolean := true;
begin
  if p_recipient_id is null or p_recipient_id = p_actor_id then
    return;
  end if;

  select
    pref.in_app_enabled,
    pref.task_updates,
    pref.quote_updates,
    pref.message_updates,
    pref.delivery_updates,
    pref.project_updates
  into
    v_in_app_enabled,
    v_task_updates,
    v_quote_updates,
    v_message_updates,
    v_delivery_updates,
    v_project_updates
  from public.notification_preferences pref
  where pref.user_id = p_recipient_id;

  -- No preference row means the account keeps the notification defaults on.
  if not found then
    v_in_app_enabled := true;
    v_task_updates := true;
    v_quote_updates := true;
    v_message_updates := true;
    v_delivery_updates := true;
    v_project_updates := true;
  end if;

  if not coalesce(v_in_app_enabled, true) then
    return;
  end if;

  if p_notification_type in (
    'task_invitation_received',
    'task_invitation_rejected'
  ) then
    v_category_enabled := coalesce(v_task_updates, true);
  elsif p_notification_type in (
    'quote_received',
    'client_counteroffer_received',
    'engineer_counteroffer_received',
    'quote_accepted',
    'quote_rejected'
  ) then
    v_category_enabled := coalesce(v_quote_updates, true);
  elsif p_notification_type = 'project_message_received' then
    v_category_enabled := coalesce(v_message_updates, true);
  elsif p_notification_type in (
    'delivery_submitted',
    'revision_requested',
    'delivery_approved'
  ) then
    v_category_enabled := coalesce(v_delivery_updates, true);
  elsif p_notification_type = 'contract_confirmed' then
    v_category_enabled := coalesce(v_project_updates, true);
  end if;

  if not v_category_enabled then
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

notify pgrst, 'reload schema';

-- WorkBridge / permit_plans: authenticated Help & Support requests.
-- Requires migration 001 (profiles/user_roles). This migration stores support
-- tickets only; it does not send email, create refunds or move payments.

create table if not exists public.support_requests (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  account_role text not null check (account_role in ('client', 'engineer', 'admin')),
  category text not null check (category in (
    'account_profile',
    'tasks_invitations',
    'quotes_contracts',
    'chat_delivery',
    'payments_payouts',
    'project_payment_dispute',
    'technical_issue',
    'other'
  )),
  subject text not null,
  message text not null,
  related_reference text,
  status text not null default 'open'
    check (status in ('open', 'in_review', 'waiting_for_user', 'resolved', 'closed')),
  admin_note text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  resolved_at timestamptz,
  constraint support_requests_subject_length check (
    pg_catalog.char_length(pg_catalog.btrim(subject)) between 5 and 140
  ),
  constraint support_requests_message_length check (
    pg_catalog.char_length(pg_catalog.btrim(message)) between 20 and 5000
  ),
  constraint support_requests_reference_length check (
    related_reference is null or pg_catalog.char_length(related_reference) <= 100
  ),
  constraint support_requests_admin_note_length check (
    admin_note is null or pg_catalog.char_length(admin_note) <= 3000
  )
);

create index if not exists support_requests_user_created_idx
  on public.support_requests (user_id, created_at desc);
create index if not exists support_requests_status_created_idx
  on public.support_requests (status, created_at desc);

alter table public.support_requests enable row level security;
revoke all on table public.support_requests from anon, authenticated;
grant select on table public.support_requests to authenticated;
grant update (status, admin_note, updated_at, resolved_at)
  on table public.support_requests to authenticated;

drop policy if exists "Users can read their own support requests"
  on public.support_requests;
create policy "Users can read their own support requests"
  on public.support_requests for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Admins can read all support requests"
  on public.support_requests;
create policy "Admins can read all support requests"
  on public.support_requests for select to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      where ur.user_id = (select auth.uid())
        and ur.role = 'admin'
    )
  );

drop policy if exists "Admins can update support request status"
  on public.support_requests;
create policy "Admins can update support request status"
  on public.support_requests for update to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      where ur.user_id = (select auth.uid())
        and ur.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.user_roles ur
      where ur.user_id = (select auth.uid())
        and ur.role = 'admin'
    )
  );

create or replace function public.set_support_request_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := pg_catalog.now();
  if new.status = 'resolved' and old.status is distinct from new.status then
    new.resolved_at := pg_catalog.now();
  elsif new.status <> 'resolved' then
    new.resolved_at := null;
  end if;
  return new;
end;
$$;
revoke all on function public.set_support_request_updated_at()
  from public, anon, authenticated;

drop trigger if exists support_requests_set_updated_at
  on public.support_requests;
create trigger support_requests_set_updated_at
  before update on public.support_requests
  for each row execute function public.set_support_request_updated_at();

-- The client cannot choose a recipient or assign an Admin. The authenticated
-- identity and role are read from Supabase's protected user_roles table.
create or replace function public.submit_support_request(
  p_category text,
  p_subject text,
  p_message text,
  p_related_reference text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_request_id uuid;
  v_subject text := pg_catalog.btrim(coalesce(p_subject, ''));
  v_message text := pg_catalog.btrim(coalesce(p_message, ''));
  v_reference text := nullif(pg_catalog.btrim(coalesce(p_related_reference, '')), '');
  v_recent_count integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role not in ('client', 'engineer', 'admin') or v_role is null then
    raise exception 'A valid WorkBridge account is required' using errcode = '42501';
  end if;

  if p_category is null or p_category not in (
    'account_profile', 'tasks_invitations', 'quotes_contracts',
    'chat_delivery', 'payments_payouts', 'project_payment_dispute',
    'technical_issue', 'other'
  ) then
    raise exception 'Choose a valid support category' using errcode = '22023';
  end if;

  if pg_catalog.char_length(v_subject) not between 5 and 140 then
    raise exception 'Subject must be between 5 and 140 characters' using errcode = '22023';
  end if;
  if pg_catalog.char_length(v_message) not between 20 and 5000 then
    raise exception 'Details must be between 20 and 5000 characters' using errcode = '22023';
  end if;
  if v_reference is not null and pg_catalog.char_length(v_reference) > 100 then
    raise exception 'Project reference must be 100 characters or fewer' using errcode = '22023';
  end if;

  select pg_catalog.count(*)::integer into v_recent_count
  from public.support_requests sr
  where sr.user_id = v_user_id
    and sr.created_at > pg_catalog.now() - interval '1 hour';

  if v_recent_count >= 5 then
    raise exception 'Too many support requests in the last hour' using errcode = 'P0001';
  end if;

  insert into public.support_requests (
    user_id, account_role, category, subject, message, related_reference
  ) values (
    v_user_id, v_role, p_category, v_subject, v_message, v_reference
  ) returning id into v_request_id;

  return v_request_id;
end;
$function$;

revoke all on function public.submit_support_request(text, text, text, text)
  from public, anon;
grant execute on function public.submit_support_request(text, text, text, text)
  to authenticated;

-- Enable live support-ticket status updates when the hosted project has the
-- standard Supabase Realtime publication installed.
do $$
begin
  if exists (
    select 1 from pg_catalog.pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_requests'
  ) then
    execute 'alter publication supabase_realtime add table public.support_requests';
  end if;
end;
$$;

notify pgrst, 'reload schema';

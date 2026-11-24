-- WorkBridge Screen 31: secure account-deletion request workflow.
-- Submitting a request does NOT delete the Supabase Auth user.
-- Support/admin must review active projects, financial records and retention
-- obligations before any separately authorised deletion process is performed.

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  email text not null,
  account_role text not null
    check (account_role in ('client', 'engineer', 'admin')),
  reason text,
  status text not null default 'requested'
    check (status in ('requested', 'under_review', 'scheduled', 'completed', 'rejected')),
  requested_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists account_deletion_requests_user_requested_idx
  on public.account_deletion_requests (user_id, requested_at desc);

create unique index if not exists account_deletion_requests_one_active_per_user_idx
  on public.account_deletion_requests (user_id)
  where status in ('requested', 'under_review', 'scheduled');

alter table public.account_deletion_requests enable row level security;

revoke all on public.account_deletion_requests from anon, authenticated;
grant select on public.account_deletion_requests to authenticated;

drop policy if exists "Users and admins can read account deletion requests"
  on public.account_deletion_requests;
create policy "Users and admins can read account deletion requests"
  on public.account_deletion_requests
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.user_roles ur
      where ur.user_id = auth.uid()
        and ur.role = 'admin'
    )
  );

create or replace function public.request_account_deletion(p_reason text default null)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text := auth.jwt() ->> 'email';
  v_role text;
  v_existing_id uuid;
  v_new_id uuid;
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if v_email is null or length(trim(v_email)) = 0 then
    raise exception 'Account email is unavailable';
  end if;

  if v_reason is not null and length(v_reason) > 1000 then
    raise exception 'Reason must be 1000 characters or fewer';
  end if;

  select ur.role
    into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  if v_role is null or v_role not in ('client', 'engineer', 'admin') then
    raise exception 'Account role could not be verified';
  end if;

  select r.id
    into v_existing_id
  from public.account_deletion_requests r
  where r.user_id = v_user_id
    and r.status in ('requested', 'under_review', 'scheduled')
  order by r.requested_at desc
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  insert into public.account_deletion_requests (
    user_id,
    email,
    account_role,
    reason
  ) values (
    v_user_id,
    trim(v_email),
    v_role,
    v_reason
  )
  returning id into v_new_id;

  return v_new_id;
exception
  when unique_violation then
    select r.id
      into v_existing_id
    from public.account_deletion_requests r
    where r.user_id = v_user_id
      and r.status in ('requested', 'under_review', 'scheduled')
    order by r.requested_at desc
    limit 1;
    return v_existing_id;
end;
$$;

revoke all on function public.request_account_deletion(text) from public;
revoke all on function public.request_account_deletion(text) from anon;
grant execute on function public.request_account_deletion(text) to authenticated;

comment on table public.account_deletion_requests is
  'Account deletion requests only. Rows are retained for support review; creating a request never deletes auth.users or marketplace records.';

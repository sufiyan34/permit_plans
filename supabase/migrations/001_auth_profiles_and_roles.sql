-- WorkBridge / permit_plans authentication foundation.
-- Run this migration in Supabase SQL Editor (or through Supabase CLI).
-- Public sign-ups may become only 'client' or 'engineer'. Admin is assigned
-- separately by a trusted administrator using SQL/service-role backend code.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text not null default '',
  avatar_url text,
  country_code text,
  timezone text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null check (role in ('client', 'engineer', 'admin')),
  created_at timestamptz not null default pg_catalog.now()
);

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;

-- Revoke broad defaults, then grant only the operations needed by app users.
revoke all on table public.profiles from anon, authenticated;
revoke all on table public.user_roles from anon, authenticated;

grant usage on schema public to authenticated;
grant select on table public.profiles to authenticated;
grant update (full_name, avatar_url, country_code, timezone)
  on table public.profiles to authenticated;
grant select on table public.user_roles to authenticated;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "Users can read their own role" on public.user_roles;
create policy "Users can read their own role"
  on public.user_roles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- The user_roles table intentionally has no INSERT/UPDATE/DELETE grant or
-- policy for anon/authenticated. This prevents users from promoting themselves.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- The trigger runs with the function owner's privileges. It copies user
-- metadata only at account creation; RLS authorization uses user_roles instead
-- of editable auth metadata.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text;
  requested_name text;
begin
  requested_role := pg_catalog.lower(
    coalesce(new.raw_user_meta_data ->> 'account_role', 'client')
  );

  if requested_role not in ('client', 'engineer') then
    requested_role := 'client';
  end if;

  requested_name := pg_catalog.btrim(
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  );

  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, requested_name)
  on conflict (id) do update
    set email = excluded.email;

  insert into public.user_roles (user_id, role)
  values (new.id, requested_role)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_auth_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Admin assignment example (run only from the Supabase SQL Editor after
-- identifying the intended auth.users.id):
-- insert into public.user_roles (user_id, role)
-- values ('AUTH_USER_UUID_HERE', 'admin')
-- on conflict (user_id) do update set role = excluded.role;

-- OPTIONAL one-time backfill: accounts created BEFORE this migration ran have
-- no profile/role row, so the app refuses to sign them in ("account role is
-- missing"). Run this once in the SQL Editor to give them the safe default
-- role (client). Promote engineers/admins afterwards with the statement above.
-- insert into public.profiles (id, email)
--   select id, email from auth.users
--   on conflict (id) do nothing;
-- insert into public.user_roles (user_id, role)
--   select id, 'client' from auth.users
--   on conflict (user_id) do nothing;

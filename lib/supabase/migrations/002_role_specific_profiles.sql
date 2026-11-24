-- WorkBridge / permit_plans: role-specific onboarding profiles.
-- Requires 001_auth_profiles_and_roles.sql to have been applied first.
-- Run once in Supabase SQL Editor or with `supabase db push`.

-- ---------------------------------------------------------------------------
-- Shared profile fields
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists country_name text,
  add column if not exists profile_completed boolean not null default false;

grant update (full_name, avatar_url, country_code, country_name, timezone)
  on table public.profiles to authenticated;

-- Admins may inspect profiles for support/moderation. Ordinary users still see
-- only their own base profile through the policy from migration 001.
drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles"
  on public.profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      where ur.user_id = (select auth.uid())
        and ur.role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- Client profile
-- ---------------------------------------------------------------------------
create table if not exists public.client_profiles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  account_type text not null default 'individual'
    check (account_type in ('individual', 'company')),
  phone_number text,
  company_name text,
  company_website text,
  about text,
  updated_at timestamptz not null default pg_catalog.now(),
  constraint client_company_name_required
    check (account_type <> 'company' or nullif(pg_catalog.btrim(company_name), '') is not null)
);

alter table public.client_profiles enable row level security;
drop trigger if exists set_client_profiles_updated_at on public.client_profiles;
create trigger set_client_profiles_updated_at
  before update on public.client_profiles
  for each row execute function public.set_updated_at();
revoke all on table public.client_profiles from anon, authenticated;
grant select, insert, update on table public.client_profiles to authenticated;

drop policy if exists "Clients can read their own client profile" on public.client_profiles;
create policy "Clients can read their own client profile"
  on public.client_profiles for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'admin'
    )
  );

drop policy if exists "Clients can create their own client profile" on public.client_profiles;
create policy "Clients can create their own client profile"
  on public.client_profiles for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'client'
    )
  );

drop policy if exists "Clients can update their own client profile" on public.client_profiles;
create policy "Clients can update their own client profile"
  on public.client_profiles for update to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'client'
    )
  )
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'client'
    )
  );

-- ---------------------------------------------------------------------------
-- Engineer profile
-- ---------------------------------------------------------------------------
create table if not exists public.engineer_profiles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  headline text not null,
  bio text not null,
  experience_level text not null default 'intermediate'
    check (experience_level in ('beginner', 'intermediate', 'expert')),
  years_experience smallint not null default 0
    check (years_experience between 0 and 60),
  availability text not null default 'available'
    check (availability in ('available', 'limited', 'unavailable')),
  skills text[] not null default '{}'::text[],
  languages text[] not null default '{}'::text[],
  portfolio_links text[] not null default '{}'::text[],
  updated_at timestamptz not null default pg_catalog.now(),
  constraint engineer_headline_not_blank check (nullif(pg_catalog.btrim(headline), '') is not null),
  constraint engineer_bio_minimum check (pg_catalog.length(pg_catalog.btrim(bio)) >= 30),
  constraint engineer_skills_required check (pg_catalog.cardinality(skills) > 0)
);

alter table public.engineer_profiles enable row level security;
drop trigger if exists set_engineer_profiles_updated_at on public.engineer_profiles;
create trigger set_engineer_profiles_updated_at
  before update on public.engineer_profiles
  for each row execute function public.set_updated_at();
create index if not exists engineer_profiles_skills_gin
  on public.engineer_profiles using gin (skills);
revoke all on table public.engineer_profiles from anon, authenticated;
grant select, insert, update on table public.engineer_profiles to authenticated;

drop policy if exists "Engineers can read their own engineer profile" on public.engineer_profiles;
create policy "Engineers can read their own engineer profile"
  on public.engineer_profiles for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'admin'
    )
  );

drop policy if exists "Engineers can create their own engineer profile" on public.engineer_profiles;
create policy "Engineers can create their own engineer profile"
  on public.engineer_profiles for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'engineer'
    )
  );

drop policy if exists "Engineers can update their own engineer profile" on public.engineer_profiles;
create policy "Engineers can update their own engineer profile"
  on public.engineer_profiles for update to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'engineer'
    )
  )
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role = 'engineer'
    )
  );

-- ---------------------------------------------------------------------------
-- Completion RPC: clients cannot set profiles.profile_completed directly.
-- It verifies the role-specific row and required fields on the server.
-- ---------------------------------------------------------------------------
create or replace function public.mark_marketplace_profile_complete()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_full_name text;
  v_country_name text;
  v_account_type text;
  v_company_name text;
  v_headline text;
  v_bio text;
  v_skills text[];
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_user_id;

  select p.full_name, p.country_name
    into v_full_name, v_country_name
  from public.profiles p
  where p.id = v_user_id;

  if nullif(pg_catalog.btrim(coalesce(v_full_name, '')), '') is null then
    raise exception 'Full name is required';
  end if;
  if nullif(pg_catalog.btrim(coalesce(v_country_name, '')), '') is null then
    raise exception 'Country is required';
  end if;

  if v_role = 'client' then
    select cp.account_type, cp.company_name
      into v_account_type, v_company_name
    from public.client_profiles cp
    where cp.user_id = v_user_id;

    if v_account_type is null then
      raise exception 'Client profile details are required';
    end if;
    if v_account_type = 'company'
       and nullif(pg_catalog.btrim(coalesce(v_company_name, '')), '') is null then
      raise exception 'Company name is required';
    end if;
  elsif v_role = 'engineer' then
    select ep.headline, ep.bio, ep.skills
      into v_headline, v_bio, v_skills
    from public.engineer_profiles ep
    where ep.user_id = v_user_id;

    if nullif(pg_catalog.btrim(coalesce(v_headline, '')), '') is null then
      raise exception 'Professional headline is required';
    end if;
    if pg_catalog.length(pg_catalog.btrim(coalesce(v_bio, ''))) < 30 then
      raise exception 'Professional bio must contain at least 30 characters';
    end if;
    if coalesce(pg_catalog.cardinality(v_skills), 0) = 0 then
      raise exception 'At least one professional skill is required';
    end if;
  elsif v_role = 'admin' then
    update public.profiles
      set profile_completed = true, updated_at = pg_catalog.now()
      where id = v_user_id;
    return true;
  else
    raise exception 'A valid marketplace role is required';
  end if;

  update public.profiles
    set profile_completed = true, updated_at = pg_catalog.now()
    where id = v_user_id;

  return true;
end;
$$;

revoke all on function public.mark_marketplace_profile_complete() from public, anon;
grant execute on function public.mark_marketplace_profile_complete() to authenticated;

-- ---------------------------------------------------------------------------
-- Public profile-avatar bucket. Object paths must start with the user's UUID.
-- The bucket contains only profile photos, not private project deliverables.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-avatars',
  'profile-avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can upload their own profile avatar" on storage.objects;
create policy "Users can upload their own profile avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can update their own profile avatar" on storage.objects;
create policy "Users can update their own profile avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'profile-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'profile-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can delete their own profile avatar" on storage.objects;
create policy "Users can delete their own profile avatar"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'profile-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

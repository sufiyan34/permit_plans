-- WorkBridge / permit_plans: repair role lookup access and backfill older accounts.
-- IMPORTANT: Run migration 001_auth_profiles_and_roles.sql first.
-- Then run this file in Supabase SQL Editor (or copy it to the root
-- supabase/migrations/ folder and apply it with the Supabase CLI).
--
-- This does NOT guess a user's role. It backfills only accounts whose
-- auth metadata contains account_role = 'client' or 'engineer'.

-- 1) Ensure authenticated users can read only their own role (RLS still applies).
grant usage on schema public to authenticated;
alter table public.user_roles enable row level security;
revoke all on table public.user_roles from anon, authenticated;
grant select on table public.user_roles to authenticated;

drop policy if exists "Users can read their own role" on public.user_roles;
create policy "Users can read their own role"
   on public.user_roles
   for select
   to authenticated
   using ((select auth.uid()) = user_id);

-- 2) Backfill base profiles for users created before migration 001 was installed.
--    Existing non-empty names are preserved.
insert into public.profiles as current_profile (id, email, full_name)
 select
   u.id,
   u.email,
   coalesce(u.raw_user_meta_data ->> 'full_name', '')
from auth.users u
where u.raw_user_meta_data ->> 'account_role' in ('client', 'engineer')
on conflict (id) do update
 set
   email = excluded.email,
   full_name = case
     when nullif(pg_catalog.btrim(current_profile.full_name), '') is null
       then excluded.full_name
     else current_profile.full_name
   end;

-- 3) Backfill roles only when valid role metadata is present.
--    Existing roles are never overwritten.
insert into public.user_roles (user_id, role)
 select
   u.id,
   u.raw_user_meta_data ->> 'account_role'
from auth.users u
where u.raw_user_meta_data ->> 'account_role' in ('client', 'engineer')
on conflict (user_id) do nothing;

-- 4) Ask PostgREST to refresh its schema cache after DDL/permissions changes.
notify pgrst, 'reload schema';

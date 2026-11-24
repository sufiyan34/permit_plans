-- WorkBridge: secure, read-only engineer directory for authenticated clients.
-- Requires migrations 001_auth_profiles_and_roles.sql and
-- 002_role_specific_profiles.sql to have been applied first.
--
-- The application must NOT grant clients broad SELECT access to profiles or
-- engineer_profiles. This SECURITY DEFINER RPC returns only fields intended
-- for an engineer's public marketplace profile. Email, phone and payout data
-- are deliberately excluded.

create index if not exists engineer_profiles_directory_updated_idx
  on public.engineer_profiles (updated_at desc, user_id);

create index if not exists profiles_completed_country_idx
  on public.profiles (country_name)
  where profile_completed = true;

create or replace function public.browse_engineers(
  p_search text default null,
  p_country_name text default null,
  p_skill text default null,
  p_experience_level text default null,
  p_availability text default null,
  p_sort text default 'recent',
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  user_id uuid,
  full_name text,
  avatar_url text,
  country_name text,
  headline text,
  bio text,
  experience_level text,
  years_experience smallint,
  availability text,
  skills text[],
  languages text[],
  portfolio_links text[],
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_search text := nullif(pg_catalog.btrim(coalesce(p_search, '')), '');
  v_country text := nullif(pg_catalog.btrim(coalesce(p_country_name, '')), '');
  v_skill text := nullif(pg_catalog.btrim(coalesce(p_skill, '')), '');
  v_experience text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_experience_level, ''))), '');
  v_availability text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_availability, ''))), '');
  v_sort text := coalesce(nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_sort, ''))), ''), 'recent');
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
  v_offset integer := greatest(0, least(coalesce(p_offset, 0), 100000));
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role
    into v_role
  from public.user_roles as ur
  where ur.user_id = v_user_id;

  if v_role is distinct from 'client' and v_role is distinct from 'admin' then
    raise exception 'Only clients can browse the engineer directory' using errcode = '42501';
  end if;

  if v_experience is not null
     and v_experience not in ('beginner', 'intermediate', 'expert') then
    raise exception 'Invalid experience filter' using errcode = '22023';
  end if;

  if v_availability is not null
     and v_availability not in ('available', 'limited', 'unavailable') then
    raise exception 'Invalid availability filter' using errcode = '22023';
  end if;

  if v_sort not in ('recent', 'experience') then
    v_sort := 'recent';
  end if;

  return query
  select
    ep.user_id,
    coalesce(nullif(pg_catalog.btrim(p.full_name), ''), 'Marketplace engineer') as full_name,
    p.avatar_url,
    p.country_name,
    ep.headline,
    ep.bio,
    ep.experience_level,
    ep.years_experience,
    ep.availability,
    ep.skills,
    ep.languages,
    ep.portfolio_links,
    pg_catalog.count(*) over () as total_count
  from public.engineer_profiles as ep
  inner join public.profiles as p
    on p.id = ep.user_id
  inner join public.user_roles as ur
    on ur.user_id = ep.user_id
   and ur.role = 'engineer'
  where p.profile_completed = true
    and (
      v_search is null
      or p.full_name ilike ('%' || v_search || '%')
      or ep.headline ilike ('%' || v_search || '%')
      or ep.bio ilike ('%' || v_search || '%')
      or exists (
        select 1
        from pg_catalog.unnest(ep.skills) as skill_name
        where skill_name ilike ('%' || v_search || '%')
      )
    )
    and (
      v_country is null
      or coalesce(p.country_name, '') ilike ('%' || v_country || '%')
    )
    and (
      v_skill is null
      or exists (
        select 1
        from pg_catalog.unnest(ep.skills) as skill_name
        where skill_name ilike ('%' || v_skill || '%')
      )
    )
    and (v_experience is null or ep.experience_level = v_experience)
    and (v_availability is null or ep.availability = v_availability)
  order by
    case when v_sort = 'experience' then ep.years_experience end desc nulls last,
    ep.updated_at desc,
    ep.user_id
  limit v_limit
  offset v_offset;
end;
$function$;

revoke all on function public.browse_engineers(
  text, text, text, text, text, text, integer, integer
) from public, anon;
grant execute on function public.browse_engineers(
  text, text, text, text, text, text, integer, integer
) to authenticated;

comment on function public.browse_engineers(
  text, text, text, text, text, text, integer, integer
) is 'Returns a paginated, privacy-filtered directory of completed engineer profiles to signed-in clients and admins.';

notify pgrst, 'reload schema';

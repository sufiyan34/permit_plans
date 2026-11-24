-- WorkBridge AI Assistant request protection.
-- Apply after migrations 001-021. The Edge Function calls this RPC using the
-- signed-in user's JWT; no service-role key is required for quota consumption.

create table if not exists public.ai_assistant_rate_limits (
  user_id uuid not null references auth.users (id) on delete cascade,
  window_start timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  primary key (user_id, window_start)
);

alter table public.ai_assistant_rate_limits enable row level security;
revoke all on table public.ai_assistant_rate_limits from anon, authenticated;

create or replace function public.consume_workbridge_ai_quota()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_window_start timestamptz := pg_catalog.date_trunc('minute', pg_catalog.now());
  v_request_count integer;
begin
  if v_user_id is null then
    return false;
  end if;

  insert into public.ai_assistant_rate_limits as limits (
    user_id,
    window_start,
    request_count
  )
  values (v_user_id, v_window_start, 1)
  on conflict (user_id, window_start)
  do update set request_count = limits.request_count + 1
  returning request_count into v_request_count;

  -- Opportunistically clear this user's old rate-limit buckets.
  delete from public.ai_assistant_rate_limits
  where user_id = v_user_id
    and window_start < (pg_catalog.now() - interval '1 day');

  return v_request_count <= 10;
end;
$$;

revoke all on function public.consume_workbridge_ai_quota() from public, anon;
grant execute on function public.consume_workbridge_ai_quota() to authenticated;

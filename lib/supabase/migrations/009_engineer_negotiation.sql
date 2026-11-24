-- WorkBridge / permit_plans: Engineer response to Client counteroffers.
-- Requires migrations 001, 002, 005, 006, 007 and 008.
-- This migration does NOT collect card payments or hold/release funds.

create index if not exists quotes_engineer_negotiation_created_idx
  on public.quotes (engineer_id, status, updated_at desc)
  where status in (
    'pending_client_review', 'client_countered', 'engineer_countered',
    'accepted', 'rejected'
  );

-- The RPC returns only quote/task details belonging to the signed-in Engineer.
-- It exposes limited Client identity fields, not email, phone or billing data.
create or replace function public.get_engineer_negotiations(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  quote_id uuid,
  task_id uuid,
  client_id uuid,
  client_name text,
  client_avatar_url text,
  client_country text,
  task_title text,
  task_category text,
  task_description text,
  currency text,
  original_amount_minor bigint,
  current_amount_minor bigint,
  original_delivery_days integer,
  current_delivery_days integer,
  original_scope_of_work text,
  current_scope_of_work text,
  original_included_revisions integer,
  current_included_revisions integer,
  current_notes text,
  status text,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_engineer_id uuid := auth.uid();
  v_role text;
  v_status text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_status, ''))), '');
begin
  if v_engineer_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_engineer_id;

  if v_role is distinct from 'engineer' then
    raise exception 'Only Engineers can view their quote negotiations' using errcode = '42501';
  end if;

  if v_status is not null and v_status not in (
    'pending_client_review', 'client_countered', 'engineer_countered',
    'accepted', 'rejected'
  ) then
    raise exception 'Invalid negotiation status filter' using errcode = '22023';
  end if;

  return query
  select
    q.id,
    q.task_id,
    q.client_id,
    coalesce(nullif(pg_catalog.btrim(cp.full_name), ''), 'Client')::text,
    cp.avatar_url,
    cp.country_name,
    t.title,
    t.category,
    t.description,
    q.currency,
    initial.amount_minor,
    q.amount_minor,
    initial.delivery_days,
    q.delivery_days,
    initial.scope_of_work,
    q.scope_of_work,
    initial.included_revisions,
    q.included_revisions,
    q.notes,
    q.status,
    q.updated_at
  from public.quotes q
  join public.tasks t on t.id = q.task_id
  join public.profiles cp on cp.id = q.client_id
  left join lateral (
    select qr.amount_minor, qr.delivery_days, qr.scope_of_work,
           qr.included_revisions
    from public.quote_revisions qr
    where qr.quote_id = q.id
      and qr.revision_number = 1
    limit 1
  ) initial on true
  where q.engineer_id = v_engineer_id
    and q.status in (
      'pending_client_review', 'client_countered', 'engineer_countered',
      'accepted', 'rejected'
    )
    and (v_status is null or q.status = v_status)
  order by
    case q.status
      when 'client_countered' then 0
      when 'pending_client_review' then 1
      when 'engineer_countered' then 2
      when 'accepted' then 3
      else 4
    end,
    q.updated_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100))
  offset greatest(0, least(coalesce(p_offset, 0), 100000));
end;
$function$;

revoke all on function public.get_engineer_negotiations(text, integer, integer)
  from public, anon;
grant execute on function public.get_engineer_negotiations(text, integer, integer)
  to authenticated;

comment on function public.get_engineer_negotiations(text, integer, integer) is
  'Returns a privacy-filtered quote inbox for the signed-in Engineer, including initial and current terms.';

-- Engineer may accept or reject the Client's counteroffer, or make another
-- counteroffer. New terms are appended to quote_revisions and never overwrite
-- the negotiation history. Accepting only advances to awaiting_payment.
create or replace function public.respond_to_engineer_counteroffer(
  p_quote_id uuid,
  p_action text,
  p_amount_minor bigint default null,
  p_delivery_days integer default null,
  p_scope_of_work text default null,
  p_included_revisions integer default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_engineer_id uuid := auth.uid();
  v_role text;
  v_task_id uuid;
  v_quote_engineer_id uuid;
  v_status text;
  v_currency text;
  v_scope text := pg_catalog.btrim(coalesce(p_scope_of_work, ''));
  v_notes text := nullif(pg_catalog.btrim(coalesce(p_notes, '')), '');
  v_revision_number integer;
begin
  if v_engineer_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_engineer_id;

  if v_role is distinct from 'engineer' then
    raise exception 'Only Engineers can respond to their counteroffers' using errcode = '42501';
  end if;

  if p_action is null or p_action not in ('accept', 'reject', 'counteroffer') then
    raise exception 'Unsupported negotiation action' using errcode = '22023';
  end if;

  select q.task_id, q.engineer_id, q.status, q.currency
    into v_task_id, v_quote_engineer_id, v_status, v_currency
  from public.quotes q
  where q.id = p_quote_id
  for update;

  if v_task_id is null or v_quote_engineer_id is distinct from v_engineer_id then
    raise exception 'Quote not found for this Engineer' using errcode = 'P0002';
  end if;

  if v_status is distinct from 'client_countered' then
    raise exception 'This quote is not waiting for an Engineer response' using errcode = 'P0001';
  end if;

  perform 1
  from public.tasks t
  where t.id = v_task_id
    and t.engineer_id = v_engineer_id
    and t.status = 'negotiating'
  for update;

  if not found then
    raise exception 'Task is not available for negotiation' using errcode = 'P0001';
  end if;

  if p_action = 'accept' then
    update public.quotes
    set status = 'accepted', updated_at = pg_catalog.now()
    where id = p_quote_id and engineer_id = v_engineer_id;

    update public.tasks
    set status = 'awaiting_payment', updated_at = pg_catalog.now()
    where id = v_task_id and engineer_id = v_engineer_id;

    return p_quote_id;
  end if;

  if p_action = 'reject' then
    update public.quotes
    set status = 'rejected', updated_at = pg_catalog.now()
    where id = p_quote_id and engineer_id = v_engineer_id;

    update public.tasks
    set status = 'quote_rejected', updated_at = pg_catalog.now()
    where id = v_task_id and engineer_id = v_engineer_id;

    return p_quote_id;
  end if;

  if p_amount_minor is null or p_amount_minor <= 0
     or p_amount_minor > 9000000000000000 then
    raise exception 'Counteroffer amount must be greater than zero' using errcode = '22023';
  end if;
  if p_delivery_days is null or p_delivery_days not between 1 and 3650 then
    raise exception 'Delivery estimate must be between 1 and 3650 days' using errcode = '22023';
  end if;
  if pg_catalog.length(v_scope) not between 30 and 6000 then
    raise exception 'Scope of work must contain between 30 and 6000 characters' using errcode = '22023';
  end if;
  if p_included_revisions is null or p_included_revisions not between 0 and 10 then
    raise exception 'Included revisions must be between 0 and 10' using errcode = '22023';
  end if;
  if v_notes is not null and pg_catalog.length(v_notes) > 2000 then
    raise exception 'Additional notes must be 2000 characters or fewer' using errcode = '22023';
  end if;

  select coalesce(pg_catalog.max(qr.revision_number), 0) + 1
    into v_revision_number
  from public.quote_revisions qr
  where qr.quote_id = p_quote_id;

  insert into public.quote_revisions (
    quote_id, revision_number, proposed_by, action,
    amount_minor, currency, delivery_days, scope_of_work,
    included_revisions, notes
  ) values (
    p_quote_id, v_revision_number, v_engineer_id, 'engineer_counteroffer',
    p_amount_minor, v_currency, p_delivery_days, v_scope,
    p_included_revisions, v_notes
  );

  update public.quotes
  set amount_minor = p_amount_minor,
      delivery_days = p_delivery_days,
      scope_of_work = v_scope,
      included_revisions = p_included_revisions,
      notes = v_notes,
      status = 'engineer_countered',
      updated_at = pg_catalog.now()
  where id = p_quote_id and engineer_id = v_engineer_id;

  update public.tasks
  set status = 'negotiating', updated_at = pg_catalog.now()
  where id = v_task_id and engineer_id = v_engineer_id;

  return p_quote_id;
end;
$function$;

revoke all on function public.respond_to_engineer_counteroffer(
  uuid, text, bigint, integer, text, integer, text
) from public, anon;
grant execute on function public.respond_to_engineer_counteroffer(
  uuid, text, bigint, integer, text, integer, text
) to authenticated;

comment on function public.respond_to_engineer_counteroffer(
  uuid, text, bigint, integer, text, integer, text
) is
  'Allows the assigned Engineer to accept, reject or counteroffer a Client counteroffer. Acceptance advances only to awaiting_payment; it does not charge or hold a card payment.';

notify pgrst, 'reload schema';

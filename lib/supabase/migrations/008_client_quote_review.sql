-- WorkBridge / permit_plans: Client quote review, accept/reject and counteroffer.
-- Requires migrations 001, 002, 005, 006 and 007.
-- IMPORTANT: accepting a quote moves the task to awaiting_payment only.
-- This migration does not charge a card, capture funds or create an escrow balance.

-- A rejected quote is a terminal task outcome for this single-engineer
-- invitation. A client can create a new task/invitation for another engineer.
alter table public.tasks
  drop constraint if exists tasks_valid_status;

alter table public.tasks
  add constraint tasks_valid_status check (status in (
    'invitation_pending',
    'engineer_rejected',
    'quote_received',
    'negotiating',
    'quote_rejected',
    'awaiting_payment',
    'funded',
    'in_progress',
    'submitted',
    'revision_requested',
    'completed',
    'disputed',
    'cancelled',
    'refund_pending',
    'refunded'
  ));

create index if not exists quotes_client_review_created_idx
  on public.quotes (client_id, created_at desc)
  where status in ('pending_client_review', 'client_countered', 'engineer_countered');

-- Return only fields suitable for the authenticated Client's quote inbox.
-- No email, phone, payout account or other private Engineer information.
create or replace function public.get_client_quotes(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  quote_id uuid,
  task_id uuid,
  engineer_id uuid,
  engineer_name text,
  engineer_avatar_url text,
  engineer_country text,
  engineer_headline text,
  engineer_experience_level text,
  engineer_years_experience smallint,
  task_title text,
  task_category text,
  task_description text,
  currency text,
  amount_minor bigint,
  delivery_days integer,
  scope_of_work text,
  included_revisions integer,
  notes text,
  status text,
  submitted_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_client_id uuid := auth.uid();
  v_role text;
  v_status text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_status, ''))), '');
begin
  if v_client_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_client_id;

  if v_role is distinct from 'client' and v_role is distinct from 'admin' then
    raise exception 'Only Clients can review quotes' using errcode = '42501';
  end if;

  if v_status is not null and v_status not in (
    'pending_client_review', 'client_countered', 'engineer_countered',
    'accepted', 'rejected', 'withdrawn'
  ) then
    raise exception 'Invalid quote status filter' using errcode = '22023';
  end if;

  return query
  select
    q.id,
    q.task_id,
    q.engineer_id,
    coalesce(nullif(pg_catalog.btrim(p.full_name), ''), 'Engineer')::text,
    p.avatar_url,
    p.country_name,
    coalesce(ep.headline, '')::text,
    ep.experience_level,
    ep.years_experience,
    t.title,
    t.category,
    t.description,
    q.currency,
    q.amount_minor,
    q.delivery_days,
    q.scope_of_work,
    q.included_revisions,
    q.notes,
    q.status,
    q.created_at,
    q.updated_at
  from public.quotes q
  join public.tasks t on t.id = q.task_id
  join public.profiles p on p.id = q.engineer_id
  left join public.engineer_profiles ep on ep.user_id = q.engineer_id
  where q.client_id = v_client_id
    and (v_status is null or q.status = v_status)
  order by
    case
      when q.status in ('pending_client_review', 'engineer_countered') then 0
      when q.status = 'client_countered' then 1
      when q.status = 'accepted' then 2
      else 3
    end,
    q.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100))
  offset greatest(0, least(coalesce(p_offset, 0), 100000));
end;
$function$;

revoke all on function public.get_client_quotes(text, integer, integer)
  from public, anon;
grant execute on function public.get_client_quotes(text, integer, integer)
  to authenticated;

comment on function public.get_client_quotes(text, integer, integer) is
  'Returns a paginated, privacy-filtered list of quotes belonging to the signed-in Client.';

-- Client actions are atomic. Counteroffers append to quote_revisions and never
-- erase prior terms. Accepting only marks the task awaiting_payment; payment is
-- handled in a separate provider-backed payment flow.
create or replace function public.respond_to_client_quote(
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
  v_client_id uuid := auth.uid();
  v_role text;
  v_task_id uuid;
  v_quote_client_id uuid;
  v_status text;
  v_currency text;
  v_scope text := pg_catalog.btrim(coalesce(p_scope_of_work, ''));
  v_notes text := nullif(pg_catalog.btrim(coalesce(p_notes, '')), '');
  v_revision_number integer;
begin
  if v_client_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_client_id;

  if v_role is distinct from 'client' then
    raise exception 'Only the Client who owns the task can respond to its quote' using errcode = '42501';
  end if;

  if p_action is null or p_action not in ('accept', 'reject', 'counteroffer') then
    raise exception 'Unsupported quote action' using errcode = '22023';
  end if;

  select q.task_id, q.client_id, q.status, q.currency
    into v_task_id, v_quote_client_id, v_status, v_currency
  from public.quotes q
  where q.id = p_quote_id
  for update;

  if v_task_id is null or v_quote_client_id is distinct from v_client_id then
    raise exception 'Quote not found for this Client' using errcode = 'P0002';
  end if;

  if v_status not in ('pending_client_review', 'engineer_countered') then
    raise exception 'This quote is not waiting for a Client response' using errcode = 'P0001';
  end if;

  perform 1
  from public.tasks t
  where t.id = v_task_id
    and t.client_id = v_client_id
  for update;

  if not found then
    raise exception 'Task not found for this Client' using errcode = 'P0002';
  end if;

  if p_action = 'accept' then
    update public.quotes
    set status = 'accepted',
        updated_at = pg_catalog.now()
    where id = p_quote_id;

    update public.tasks
    set status = 'awaiting_payment',
        updated_at = pg_catalog.now()
    where id = v_task_id;

    return p_quote_id;
  end if;

  if p_action = 'reject' then
    update public.quotes
    set status = 'rejected',
        updated_at = pg_catalog.now()
    where id = p_quote_id;

    update public.tasks
    set status = 'quote_rejected',
        updated_at = pg_catalog.now()
    where id = v_task_id;

    return p_quote_id;
  end if;

  -- Counteroffer validation. The currency is locked to the Engineer's quote;
  -- the Client cannot silently switch currencies during negotiation.
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
    p_quote_id, v_revision_number, v_client_id, 'client_counteroffer',
    p_amount_minor, v_currency, p_delivery_days, v_scope,
    p_included_revisions, v_notes
  );

  update public.quotes
  set amount_minor = p_amount_minor,
      delivery_days = p_delivery_days,
      scope_of_work = v_scope,
      included_revisions = p_included_revisions,
      notes = v_notes,
      status = 'client_countered',
      updated_at = pg_catalog.now()
  where id = p_quote_id;

  update public.tasks
  set status = 'negotiating',
      updated_at = pg_catalog.now()
  where id = v_task_id;

  return p_quote_id;
end;
$function$;

revoke all on function public.respond_to_client_quote(
  uuid, text, bigint, integer, text, integer, text
) from public, anon;
grant execute on function public.respond_to_client_quote(
  uuid, text, bigint, integer, text, integer, text
) to authenticated;

comment on function public.respond_to_client_quote(
  uuid, text, bigint, integer, text, integer, text
) is
  'Allows the owning Client to accept, reject or counteroffer a quote. Accept only moves the task to awaiting_payment; it does not collect or hold funds.';

notify pgrst, 'reload schema';

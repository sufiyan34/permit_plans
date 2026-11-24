-- WorkBridge / permit_plans: first Engineer quote submission.
-- Requires migrations 001, 002, 005 and 006.
-- This migration does not create a payment, authorize a card, or hold funds.

create table if not exists public.quotes (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  task_id uuid not null unique references public.tasks(id) on delete restrict,
  invitation_id uuid not null unique references public.task_invitations(id) on delete restrict,
  client_id uuid not null references public.profiles(id) on delete restrict,
  engineer_id uuid not null references public.profiles(id) on delete restrict,
  amount_minor bigint not null,
  currency text not null,
  delivery_days integer not null,
  scope_of_work text not null,
  included_revisions integer not null default 0,
  notes text,
  status text not null default 'pending_client_review',
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  constraint quotes_amount_positive check (amount_minor > 0),
  constraint quotes_currency_code check (currency ~ '^[A-Z]{3}$'),
  constraint quotes_delivery_days check (delivery_days between 1 and 3650),
  constraint quotes_scope_length check (
    pg_catalog.length(pg_catalog.btrim(scope_of_work)) between 30 and 6000
  ),
  constraint quotes_revisions_range check (included_revisions between 0 and 10),
  constraint quotes_notes_length check (notes is null or pg_catalog.length(notes) <= 2000),
  constraint quotes_valid_status check (status in (
    'pending_client_review',
    'client_countered',
    'engineer_countered',
    'accepted',
    'rejected',
    'withdrawn'
  )),
  constraint quotes_distinct_parties check (client_id <> engineer_id)
);

-- Immutable history of quote terms. Negotiation screens will append a new
-- revision rather than overwriting what either party previously offered.
create table if not exists public.quote_revisions (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  quote_id uuid not null references public.quotes(id) on delete restrict,
  revision_number integer not null,
  proposed_by uuid not null references public.profiles(id) on delete restrict,
  action text not null,
  amount_minor bigint not null,
  currency text not null,
  delivery_days integer not null,
  scope_of_work text not null,
  included_revisions integer not null,
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  constraint quote_revisions_unique_number unique (quote_id, revision_number),
  constraint quote_revisions_number_positive check (revision_number > 0),
  constraint quote_revisions_amount_positive check (amount_minor > 0),
  constraint quote_revisions_currency_code check (currency ~ '^[A-Z]{3}$'),
  constraint quote_revisions_delivery_days check (delivery_days between 1 and 3650),
  constraint quote_revisions_scope_length check (
    pg_catalog.length(pg_catalog.btrim(scope_of_work)) between 30 and 6000
  ),
  constraint quote_revisions_revisions_range check (included_revisions between 0 and 10),
  constraint quote_revisions_action check (action in (
    'initial', 'client_counteroffer', 'engineer_counteroffer'
  ))
);

create index if not exists quotes_client_status_created_idx
  on public.quotes(client_id, status, created_at desc);
create index if not exists quotes_engineer_status_created_idx
  on public.quotes(engineer_id, status, created_at desc);
create index if not exists quote_revisions_quote_number_idx
  on public.quote_revisions(quote_id, revision_number desc);

alter table public.quotes enable row level security;
alter table public.quote_revisions enable row level security;

revoke all on table public.quotes from anon, authenticated;
revoke all on table public.quote_revisions from anon, authenticated;
grant select on table public.quotes to authenticated;
grant select on table public.quote_revisions to authenticated;

drop policy if exists "Quote parties can read their quotes" on public.quotes;
create policy "Quote parties can read their quotes"
  on public.quotes for select to authenticated
  using (
    client_id = (select auth.uid())
    or engineer_id = (select auth.uid())
  );

drop policy if exists "Quote parties can read quote history" on public.quote_revisions;
create policy "Quote parties can read quote history"
  on public.quote_revisions for select to authenticated
  using (
    exists (
      select 1
      from public.quotes q
      where q.id = quote_revisions.quote_id
        and (
          q.client_id = (select auth.uid())
          or q.engineer_id = (select auth.uid())
        )
    )
  );

create or replace function public.submit_task_quote(
  p_invitation_id uuid,
  p_amount_minor bigint,
  p_delivery_days integer,
  p_scope_of_work text,
  p_included_revisions integer default 0,
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
  v_client_id uuid;
  v_currency text;
  v_quote_id uuid := pg_catalog.gen_random_uuid();
  v_scope text := pg_catalog.btrim(coalesce(p_scope_of_work, ''));
  v_notes text := nullif(pg_catalog.btrim(coalesce(p_notes, '')), '');
begin
  if v_engineer_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select ur.role into v_role
  from public.user_roles ur
  where ur.user_id = v_engineer_id;

  if v_role is distinct from 'engineer' then
    raise exception 'Only Engineers can submit quotes' using errcode = '42501';
  end if;

  if p_amount_minor is null or p_amount_minor <= 0 then
    raise exception 'Quote amount must be greater than zero' using errcode = '22023';
  end if;
  if p_amount_minor > 9000000000000000 then
    raise exception 'Quote amount is too large' using errcode = '22023';
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

  -- Lock both invitation and task so the same invitation cannot be quoted
  -- twice or raced against a rejection/cancellation.
  select ti.task_id, ti.client_id, t.currency
    into v_task_id, v_client_id, v_currency
  from public.task_invitations ti
  join public.tasks t on t.id = ti.task_id
  where ti.id = p_invitation_id
    and ti.engineer_id = v_engineer_id
    and ti.status = 'pending'
    and t.status = 'invitation_pending'
  for update of ti, t;

  if v_task_id is null then
    raise exception 'Invitation not found or no longer pending' using errcode = 'P0001';
  end if;

  insert into public.quotes (
    id, task_id, invitation_id, client_id, engineer_id,
    amount_minor, currency, delivery_days, scope_of_work,
    included_revisions, notes, status
  ) values (
    v_quote_id, v_task_id, p_invitation_id, v_client_id, v_engineer_id,
    p_amount_minor, v_currency, p_delivery_days, v_scope,
    p_included_revisions, v_notes, 'pending_client_review'
  );

  insert into public.quote_revisions (
    quote_id, revision_number, proposed_by, action,
    amount_minor, currency, delivery_days, scope_of_work,
    included_revisions, notes
  ) values (
    v_quote_id, 1, v_engineer_id, 'initial',
    p_amount_minor, v_currency, p_delivery_days, v_scope,
    p_included_revisions, v_notes
  );

  update public.task_invitations
  set status = 'quote_submitted',
      responded_at = pg_catalog.now()
  where id = p_invitation_id
    and engineer_id = v_engineer_id
    and status = 'pending';

  if not found then
    raise exception 'Invitation is no longer pending' using errcode = 'P0001';
  end if;

  update public.tasks
  set status = 'quote_received',
      updated_at = pg_catalog.now()
  where id = v_task_id
    and engineer_id = v_engineer_id
    and status = 'invitation_pending';

  if not found then
    raise exception 'Task is no longer awaiting an Engineer response' using errcode = 'P0001';
  end if;

  return v_quote_id;
end;
$function$;

revoke all on function public.submit_task_quote(uuid, bigint, integer, text, integer, text)
  from public, anon;
grant execute on function public.submit_task_quote(uuid, bigint, integer, text, integer, text)
  to authenticated;

comment on function public.submit_task_quote(uuid, bigint, integer, text, integer, text) is
  'Submits the invited Engineer initial quote, stores its immutable first revision, and updates invitation/task states. It does not collect or hold payment.';

notify pgrst, 'reload schema';

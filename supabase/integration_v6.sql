
-- CHRIST CONNECT V6 INTEGRATION
-- Run after schema.sql + upgrade_v2.sql + upgrade_v3.sql + upgrade_v4.sql
-- This migration only adds the database-backed Lost & Found layer and supporting indexes.

create table if not exists public.lost_found_items (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.student_profiles(id) on delete cascade,
  type text not null check (type in ('lost','found')),
  title text not null check (char_length(trim(title)) between 2 and 120),
  description text,
  category text not null default 'Other',
  location text,
  item_date date,
  status text not null default 'open' check (status in ('open','matched','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lost_found_status_created_idx
  on public.lost_found_items(status, created_at desc);

create index if not exists lost_found_student_idx
  on public.lost_found_items(student_id, created_at desc);

drop policy if exists "active canteen shops public" on public.canteen_shops;
create policy "active canteen shops public"
on public.canteen_shops
for select to anon, authenticated
using (active = true);

create table if not exists public.lost_found_claims (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.lost_found_items(id) on delete cascade,
  claimer_id uuid not null references public.student_profiles(id) on delete cascade,
  message text not null check(char_length(trim(message)) between 2 and 500),
  created_at timestamptz not null default now(),
  unique(item_id, claimer_id)
);

create index if not exists lost_found_claims_item_idx
  on public.lost_found_claims(item_id, created_at desc);

alter table public.lost_found_items enable row level security;
alter table public.lost_found_claims enable row level security;

drop policy if exists "open lost found visible" on public.lost_found_items;
create policy "open lost found visible"
on public.lost_found_items
for select to authenticated
using (status = 'open' or student_id = auth.uid());

drop policy if exists "student reports lost found" on public.lost_found_items;
create policy "student reports lost found"
on public.lost_found_items
for insert to authenticated
with check (student_id = auth.uid());

drop policy if exists "student edits own lost found" on public.lost_found_items;
create policy "student edits own lost found"
on public.lost_found_items
for update to authenticated
using (student_id = auth.uid())
with check (student_id = auth.uid());

drop policy if exists "student deletes own lost found" on public.lost_found_items;
create policy "student deletes own lost found"
on public.lost_found_items
for delete to authenticated
using (student_id = auth.uid());

drop policy if exists "students submit claims" on public.lost_found_claims;
create policy "students submit claims"
on public.lost_found_claims
for insert to authenticated
with check (claimer_id = auth.uid());

drop policy if exists "students see claims they made" on public.lost_found_claims;
create policy "students see claims they made"
on public.lost_found_claims
for select to authenticated
using (claimer_id = auth.uid());

drop policy if exists "reporters see claims on their reports" on public.lost_found_claims;
create policy "reporters see claims on their reports"
on public.lost_found_claims
for select to authenticated
using (
  exists (
    select 1
    from public.lost_found_items li
    where li.id = item_id
      and li.student_id = auth.uid()
  )
);

create or replace function public.touch_lost_found_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists lost_found_touch on public.lost_found_items;
create trigger lost_found_touch
before update on public.lost_found_items
for each row execute function public.touch_lost_found_updated_at();

-- These indexes improve the already-connected private dashboard.
create index if not exists event_registrations_student_idx
  on public.event_registrations(student_id, registered_at desc);

create index if not exists club_memberships_student_idx
  on public.club_memberships(student_id, joined_at desc);

create index if not exists notifications_student_idx
  on public.notifications(student_id, created_at desc);

-- Keep the campus organisations directory readable through the existing RLS rule.

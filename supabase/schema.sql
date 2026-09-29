-- CHRIST CONNECT · SUPABASE POSTGRES SCHEMA
create extension if not exists pgcrypto;
create extension if not exists citext;

create table if not exists public.student_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  registration_number citext unique not null,
  university_email citext unique not null,
  full_name text not null,
  school text,
  department text,
  programme text,
  batch_year smallint,
  status text not null default 'active' check (status in ('active','suspended','graduated')),
  bio text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.attendance_records (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references public.student_profiles(id) on delete cascade,
 course_code text not null, course_name text not null, sessions_held integer not null default 0 check(sessions_held>=0), sessions_attended integer not null default 0 check(sessions_attended between 0 and sessions_held), updated_at timestamptz not null default now(), unique(student_id,course_code));
create table if not exists public.events (
 id uuid primary key default gen_random_uuid(), title text not null, description text, starts_at timestamptz not null, ends_at timestamptz, location text, capacity integer, published boolean not null default false, created_at timestamptz not null default now());
create table if not exists public.event_registrations (
 student_id uuid references public.student_profiles(id) on delete cascade, event_id uuid references public.events(id) on delete cascade, registered_at timestamptz not null default now(), primary key(student_id,event_id));
create table if not exists public.clubs (
 id uuid primary key default gen_random_uuid(), name text unique not null, level text not null default 'university', school text, department text, description text, official_url text, active boolean not null default true);
create table if not exists public.club_memberships (
 student_id uuid references public.student_profiles(id) on delete cascade, club_id uuid references public.clubs(id) on delete cascade, joined_at timestamptz not null default now(), primary key(student_id,club_id));
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), student_id uuid references public.student_profiles(id) on delete cascade, title text not null, body text, is_read boolean not null default false, created_at timestamptz not null default now());
create table if not exists public.canteen_items (
 id uuid primary key default gen_random_uuid(), name text not null, category text, price numeric(10,2) not null check(price>=0), available boolean not null default true);
create table if not exists public.canteen_orders (
 id uuid primary key default gen_random_uuid(), student_id uuid references public.student_profiles(id) on delete cascade, status text not null default 'placed', total numeric(10,2) not null default 0, created_at timestamptz not null default now());
create table if not exists public.canteen_order_items (
 order_id uuid references public.canteen_orders(id) on delete cascade, item_id uuid references public.canteen_items(id), quantity integer not null check(quantity>0), unit_price numeric(10,2) not null, primary key(order_id,item_id));
create table if not exists public.audit_log (
 id bigint generated always as identity primary key, actor_id uuid references auth.users(id) on delete set null, action text not null, entity text, entity_id uuid, metadata jsonb, created_at timestamptz not null default now());

alter table public.student_profiles enable row level security; alter table public.attendance_records enable row level security; alter table public.events enable row level security; alter table public.event_registrations enable row level security; alter table public.clubs enable row level security; alter table public.club_memberships enable row level security; alter table public.notifications enable row level security; alter table public.canteen_items enable row level security; alter table public.canteen_orders enable row level security; alter table public.canteen_order_items enable row level security; alter table public.audit_log enable row level security;

do $$ begin
create policy "student reads own profile" on public.student_profiles for select to authenticated using (id=auth.uid());
create policy "student updates own profile" on public.student_profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy "student reads own attendance" on public.attendance_records for select to authenticated using (student_id=auth.uid());
create policy "published events are visible" on public.events for select to authenticated using (published=true);
create policy "student reads own registrations" on public.event_registrations for select to authenticated using (student_id=auth.uid());
create policy "student registers self" on public.event_registrations for insert to authenticated with check (student_id=auth.uid());
create policy "student cancels own registration" on public.event_registrations for delete to authenticated using (student_id=auth.uid());
create policy "active clubs visible" on public.clubs for select to authenticated using (active=true);
create policy "student reads own memberships" on public.club_memberships for select to authenticated using (student_id=auth.uid());
create policy "student joins self" on public.club_memberships for insert to authenticated with check (student_id=auth.uid());
create policy "student leaves own membership" on public.club_memberships for delete to authenticated using (student_id=auth.uid());
create policy "student reads own notifications" on public.notifications for select to authenticated using (student_id=auth.uid());
create policy "student updates own notifications" on public.notifications for update to authenticated using (student_id=auth.uid()) with check (student_id=auth.uid());
create policy "menu visible" on public.canteen_items for select to authenticated using (available=true);
create policy "student reads own orders" on public.canteen_orders for select to authenticated using (student_id=auth.uid());
create policy "student reads own order items" on public.canteen_order_items for select to authenticated using (exists(select 1 from public.canteen_orders o where o.id=order_id and o.student_id=auth.uid()));
exception when duplicate_object then null; end $$;

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists student_profiles_touch on public.student_profiles; create trigger student_profiles_touch before update on public.student_profiles for each row execute function public.touch_updated_at();

-- Demo event/club data only. Do not treat these as official university records.
insert into public.events(title,description,starts_at,location,published) values
('Christ Connect Demo Orientation','Demo event for testing the student portal.',now()+interval '3 days','Delhi NCR Campus',true),
('Student Innovation Meetup','Demo community event.',now()+interval '7 days','Innovation Lab',true) on conflict do nothing;
insert into public.clubs(name,level,description) values ('Code Collective','university','Demo technology community.'),('Creative Society','university','Demo creative community.') on conflict(name) do nothing;

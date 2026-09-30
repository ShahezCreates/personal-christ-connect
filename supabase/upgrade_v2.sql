-- CHRIST CONNECT V2 · private student enhancements
-- Safe to run after the existing Christ Connect schema.
-- Demo rows are clearly marked and are only for DEMO2026BCA001.

alter table public.student_profiles add column if not exists phone text;
alter table public.student_profiles add column if not exists semester smallint;
alter table public.student_profiles add column if not exists section text;
alter table public.student_profiles add column if not exists campus text default 'Delhi NCR · Mariam Nagar';

create table if not exists public.student_skills (
  student_id uuid not null references public.student_profiles(id) on delete cascade,
  skill text not null check(char_length(trim(skill)) between 1 and 80),
  created_at timestamptz not null default now(),
  primary key(student_id, skill)
);

create table if not exists public.student_interests (
  student_id uuid not null references public.student_profiles(id) on delete cascade,
  interest text not null check(char_length(trim(interest)) between 1 and 80),
  created_at timestamptz not null default now(),
  primary key(student_id, interest)
);

create table if not exists public.student_preferences (
  student_id uuid primary key references public.student_profiles(id) on delete cascade,
  email_notifications boolean not null default true,
  marketplace_alerts boolean not null default true,
  skill_suggestions boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.student_skills enable row level security;
alter table public.student_interests enable row level security;
alter table public.student_preferences enable row level security;

do $$ begin
  create policy "student reads own skills" on public.student_skills for select to authenticated using(student_id=auth.uid());
  create policy "student adds own skills" on public.student_skills for insert to authenticated with check(student_id=auth.uid());
  create policy "student removes own skills" on public.student_skills for delete to authenticated using(student_id=auth.uid());
  create policy "student reads own interests" on public.student_interests for select to authenticated using(student_id=auth.uid());
  create policy "student adds own interests" on public.student_interests for insert to authenticated with check(student_id=auth.uid());
  create policy "student removes own interests" on public.student_interests for delete to authenticated using(student_id=auth.uid());
  create policy "student manages own preferences" on public.student_preferences for all to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());
exception when duplicate_object then null; end $$;

insert into public.student_preferences(student_id)
select id from public.student_profiles
where upper(registration_number::text)='DEMO2026BCA001'
on conflict(student_id) do nothing;

insert into public.student_skills(student_id,skill)
select sp.id, v.skill
from public.student_profiles sp
cross join (values ('Figma'),('JavaScript'),('Photography'),('Public speaking')) v(skill)
where upper(sp.registration_number::text)='DEMO2026BCA001'
on conflict do nothing;

insert into public.student_interests(student_id,interest)
select sp.id, v.interest
from public.student_profiles sp
cross join (values ('Design'),('Music'),('Startups'),('Football'),('Film')) v(interest)
where upper(sp.registration_number::text)='DEMO2026BCA001'
on conflict do nothing;

insert into public.attendance_records(student_id,course_code,course_name,sessions_held,sessions_attended)
select sp.id, x.course_code, x.course_name, x.sessions_held, x.sessions_attended
from public.student_profiles sp
cross join (values
 ('CSP101','Programming in C',24,20),
 ('DLD101','Digital Logic Design',22,17),
 ('MAT101','Discrete Mathematics',20,15),
 ('ENG101','English for Academic Purpose',18,16),
 ('WEB101','Web Technologies',16,14),
 ('EVS101','Environmental Studies',14,12)
) x(course_code,course_name,sessions_held,sessions_attended)
where upper(sp.registration_number::text)='DEMO2026BCA001'
on conflict(student_id,course_code) do update set
  course_name=excluded.course_name,
  sessions_held=excluded.sessions_held,
  sessions_attended=excluded.sessions_attended,
  updated_at=now();

insert into public.notifications(student_id,title,body,is_read)
select sp.id,'Attendance dashboard is ready','Your subject-wise attendance and what-if calculator are available in your private space.',false
from public.student_profiles sp
where upper(sp.registration_number::text)='DEMO2026BCA001'
  and not exists(select 1 from public.notifications n where n.student_id=sp.id and n.title='Attendance dashboard is ready');

insert into public.event_registrations(student_id,event_id)
select sp.id,e.id
from public.student_profiles sp
cross join lateral (select id from public.events where published=true order by starts_at limit 2) e
where upper(sp.registration_number::text)='DEMO2026BCA001'
on conflict do nothing;

insert into public.club_memberships(student_id,club_id)
select sp.id,c.id
from public.student_profiles sp
cross join lateral (select id from public.clubs where active=true order by name limit 2) c
where upper(sp.registration_number::text)='DEMO2026BCA001'
on conflict do nothing;

-- CHRIST CONNECT DELHI NCR · V5 migration
-- Safe/idempotent migration for the existing Christ Connect schema.
create extension if not exists pgcrypto;
create extension if not exists citext;

alter table public.student_profiles add column if not exists phone text;
alter table public.student_profiles add column if not exists semester smallint;
alter table public.student_profiles add column if not exists section text;
alter table public.student_profiles add column if not exists campus text default 'Delhi NCR Campus';

create table if not exists public.student_skills(
  student_id uuid not null references public.student_profiles(id) on delete cascade,
  skill text not null,
  created_at timestamptz not null default now(),
  primary key(student_id,skill)
);
create table if not exists public.student_interests(
  student_id uuid not null references public.student_profiles(id) on delete cascade,
  interest text not null,
  created_at timestamptz not null default now(),
  primary key(student_id,interest)
);
create table if not exists public.student_preferences(
  student_id uuid primary key references public.student_profiles(id) on delete cascade,
  email_notifications boolean not null default true,
  marketplace_alerts boolean not null default true,
  skill_match_suggestions boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.canteen_outlets(
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  area text not null,
  category text not null,
  active boolean not null default true,
  preorder_enabled boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.canteen_menu_items(
  id uuid primary key default gen_random_uuid(),
  outlet_id uuid not null references public.canteen_outlets(id) on delete cascade,
  name text not null,
  description text,
  category text,
  price numeric(10,2) not null check(price>=0),
  available boolean not null default true,
  unique(outlet_id,name)
);
alter table public.canteen_orders add column if not exists outlet_id uuid references public.canteen_outlets(id);
alter table public.canteen_orders add column if not exists order_code text;
alter table public.canteen_orders add column if not exists pickup_date date;
alter table public.canteen_orders add column if not exists pickup_slot text;
alter table public.canteen_orders add column if not exists notes text;
alter table public.canteen_orders add column if not exists payment_status text not null default 'paid_demo';
alter table public.canteen_orders add column if not exists payment_provider text not null default 'demo';
alter table public.canteen_orders add column if not exists payment_reference text;
alter table public.canteen_orders add column if not exists cancellable_until timestamptz;
alter table public.canteen_orders add column if not exists cancelled_at timestamptz;
alter table public.canteen_orders add column if not exists receipt_code text;
alter table public.canteen_orders add column if not exists updated_at timestamptz not null default now();

create unique index if not exists canteen_orders_order_code_uq on public.canteen_orders(order_code) where order_code is not null;
create unique index if not exists canteen_orders_receipt_code_uq on public.canteen_orders(receipt_code) where receipt_code is not null;

create table if not exists public.lost_found_items(
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.student_profiles(id) on delete cascade,
  item_type text not null check(item_type in('lost','found')),
  title text not null,
  category text not null,
  description text,
  location text,
  occurred_on date,
  photo_url text,
  status text not null default 'open' check(status in('open','claimed','resolved','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.lost_found_claims(
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.lost_found_items(id) on delete cascade,
  claimant_id uuid not null references public.student_profiles(id) on delete cascade,
  message text not null,
  status text not null default 'pending' check(status in('pending','approved','rejected','withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(item_id,claimant_id)
);

-- Seed the official Delhi NCR dining outlets named by the university. Menu prices below are demo/prototype values because the public dining page does not publish price sheets.
insert into public.canteen_outlets(name,area,category) values
('Punjabi Bites','Gourmet Hall · Block A · Level -1','North Indian'),
('Southern Delights','Gourmet Hall · Block A · Level -1','South Indian'),
('Taste of Dilli','Gourmet Hall · Block A · Level -1','Vegetarian Street Food'),
('Rolls Lane','Gourmet Hall · Block A · Level -1','Quick Bites'),
('Bites & Brews','Gourmet Hall · Block A · Level -1','Café & Snacks'),
('Steaming Mugs','Rooftop Cafe · Block B terrace','Café'),
('Giani''s Ice Cream','Rooftop Cafe · Block B terrace','Desserts'),
('Domino''s','Campus dining area · basketball court side','Quick Service'),
('Fresheteria','Block C','Fresh Food & Beverages'),
('Cafe Coffee Day','Block B · Level -1','Café')
on conflict(name) do update set area=excluded.area,category=excluded.category;

insert into public.canteen_menu_items(outlet_id,name,description,category,price)
select o.id,x.name,x.description,x.category,x.price from public.canteen_outlets o join (values
('Punjabi Bites','Paneer Thali','Paneer + dal + rice + roti','Meals',95),('Punjabi Bites','Rajma Chawal','Rajma with steamed rice','Meals',75),('Punjabi Bites','Chole Bhature','Chole with two bhature','Meals',90),('Punjabi Bites','Aloo Paratha','Two parathas + curd','Quick Bites',55),
('Southern Delights','Masala Dosa','Crisp dosa with masala','South Indian',70),('Southern Delights','Idli Vada','Idli, vada and sambar','South Indian',60),('Southern Delights','Sambar Rice','Steamed rice with sambar','Meals',65),('Southern Delights','Veg Meals','South Indian meal plate','Meals',90),
('Taste of Dilli','Chole Kulche','Delhi-style chole kulche','Street Food',65),('Taste of Dilli','Aloo Tikki','Crisp potato tikki','Street Food',55),('Taste of Dilli','Veg Chowmein','Wok-tossed noodles','Quick Bites',75),('Taste of Dilli','Raj Kachori','Stuffed chaat','Street Food',65),
('Rolls Lane','Paneer Roll','Spiced paneer wrap','Rolls',80),('Rolls Lane','Veg Roll','Mixed veg wrap','Rolls',65),('Rolls Lane','Egg Roll','Egg-filled wrap','Rolls',75),('Rolls Lane','Double Paneer Roll','Extra paneer wrap','Rolls',100),
('Bites & Brews','Cold Coffee','Chilled coffee','Beverages',70),('Bites & Brews','Masala Tea','Indian milk tea','Beverages',30),('Bites & Brews','Veg Sandwich','Grilled sandwich','Snacks',65),('Bites & Brews','Brownie','Chocolate brownie','Dessert',55),
('Steaming Mugs','Cappuccino','Espresso + steamed milk','Coffee',80),('Steaming Mugs','Latte','Smooth espresso and milk','Coffee',90),('Steaming Mugs','Hot Chocolate','Rich cocoa drink','Beverages',95),('Steaming Mugs','Veg Sandwich','Café grilled sandwich','Snacks',75),
('Giani''s Ice Cream','Single Scoop','Choice of available flavour','Dessert',80),('Giani''s Ice Cream','Double Scoop','Two scoops','Dessert',120),('Giani''s Ice Cream','Sundae','Ice cream sundae','Dessert',150),('Giani''s Ice Cream','Brownie Scoop','Brownie with ice cream','Dessert',145),
('Domino''s','Regular Veg Pizza','Vegetarian pizza','Pizza',159),('Domino''s','Farmhouse Pizza','Veg farmhouse pizza','Pizza',199),('Domino''s','Garlic Bread','Garlic breadsticks','Sides',99),('Domino''s','Choco Lava Cake','Warm chocolate dessert','Dessert',109),
('Fresheteria','Fresh Orange Juice','Fresh citrus juice','Beverages',70),('Fresheteria','Mango Shake','Mango milkshake','Beverages',85),('Fresheteria','Fruit Bowl','Fresh cut fruit','Healthy',90),('Fresheteria','Veg Wrap','Fresh vegetable wrap','Snacks',85),
('Cafe Coffee Day','Cappuccino','Café cappuccino','Coffee',95),('Cafe Coffee Day','Cold Coffee','Chilled café coffee','Beverages',110),('Cafe Coffee Day','Veg Croissant','Vegetarian croissant','Bakery',90),('Cafe Coffee Day','Brownie','Chocolate brownie','Dessert',85)
) as x(outlet,name,description,category,price) on x.outlet=o.name
on conflict(outlet_id,name) do update set description=excluded.description,category=excluded.category,price=excluded.price,available=true;

-- Seed one demo student's attendance/profile-support rows only.
insert into public.student_preferences(student_id) select id from public.student_profiles where upper(registration_number::text)='DEMO2026BCA001' on conflict do nothing;
insert into public.attendance_records(student_id,course_code,course_name,sessions_held,sessions_attended)
select p.id,x.code,x.name,x.held,x.attended from public.student_profiles p join (values
('CPC101','Programming in C',26,22),('DLD101','Digital Logic Design',24,20),('MATH101','Discrete Mathematics',28,24),('ENG101','English for Academic Skills',22,19),('PHY101','Physics for Computing',20,16),('EVS101','Environmental Studies',18,17),('DIG101','Digital Literacy',16,13),('KRM101','Kannada / Language Elective',16,14)
) as x(code,name,held,attended) on true where upper(p.registration_number::text)='DEMO2026BCA001'
on conflict(student_id,course_code) do update set sessions_held=excluded.sessions_held,sessions_attended=excluded.sessions_attended,updated_at=now();

-- RLS
alter table public.student_skills enable row level security;
alter table public.student_interests enable row level security;
alter table public.student_preferences enable row level security;
alter table public.canteen_outlets enable row level security;
alter table public.canteen_menu_items enable row level security;
alter table public.lost_found_items enable row level security;
alter table public.lost_found_claims enable row level security;

drop policy if exists "student reads own skills" on public.student_skills;
create policy "student reads own skills" on public.student_skills for select to authenticated using(student_id=auth.uid());
drop policy if exists "student manages own skills" on public.student_skills;
create policy "student manages own skills" on public.student_skills for all to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());
drop policy if exists "student reads own interests" on public.student_interests;
create policy "student reads own interests" on public.student_interests for select to authenticated using(student_id=auth.uid());
drop policy if exists "student manages own interests" on public.student_interests;
create policy "student manages own interests" on public.student_interests for all to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());
drop policy if exists "student reads own preferences" on public.student_preferences;
create policy "student reads own preferences" on public.student_preferences for select to authenticated using(student_id=auth.uid());
drop policy if exists "student manages own preferences" on public.student_preferences;
create policy "student manages own preferences" on public.student_preferences for all to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());

drop policy if exists "authenticated can read active outlets" on public.canteen_outlets;
create policy "authenticated can read active outlets" on public.canteen_outlets for select to authenticated using(active=true and preorder_enabled=true);
drop policy if exists "authenticated can read available outlet menu" on public.canteen_menu_items;
create policy "authenticated can read available outlet menu" on public.canteen_menu_items for select to authenticated using(available=true);

drop policy if exists "students can browse lost found" on public.lost_found_items;
create policy "students can browse lost found" on public.lost_found_items for select to authenticated using(status in ('open','claimed') or owner_id=auth.uid());
drop policy if exists "students can report lost found" on public.lost_found_items;
create policy "students can report lost found" on public.lost_found_items for insert to authenticated with check(owner_id=auth.uid());
drop policy if exists "students can update own lost found" on public.lost_found_items;
create policy "students can update own lost found" on public.lost_found_items for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
drop policy if exists "students can read relevant claims" on public.lost_found_claims;
create policy "students can read relevant claims" on public.lost_found_claims for select to authenticated using(claimant_id=auth.uid() or exists(select 1 from public.lost_found_items i where i.id=item_id and i.owner_id=auth.uid()));
drop policy if exists "students can submit claims" on public.lost_found_claims;
create policy "students can submit claims" on public.lost_found_claims for insert to authenticated with check(claimant_id=auth.uid());

-- Harden order writes: students read only; the placement/cancellation RPCs are the write path.
revoke insert,update,delete on public.canteen_orders from anon,authenticated;
revoke insert,update,delete on public.canteen_order_items from anon,authenticated;

create or replace function public.place_prepaid_canteen_order(
  p_outlet_id uuid,
  p_items jsonb,
  p_pickup_date date,
  p_pickup_slot text,
  p_notes text default null,
  p_payment_provider text default 'demo',
  p_payment_reference text default null
)
returns table(order_id uuid,order_code text,receipt_code text,total numeric,cancellable_until timestamptz)
language plpgsql
security definer
set search_path=''
as $$
declare
  outlet public.canteen_outlets%rowtype; row_item jsonb; menu_row public.canteen_menu_items%rowtype;
  oid uuid; total_cost numeric:=0; qty integer; code text; receipt text; cancel_until timestamptz;
  current_student public.student_profiles%rowtype;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  select * into current_student from public.student_profiles where id=auth.uid();
  if current_student.id is null or current_student.status <> 'active' then raise exception 'Student account is not active'; end if;
  select * into outlet from public.canteen_outlets where id=p_outlet_id and active and preorder_enabled;
  if outlet.id is null then raise exception 'This outlet is not available for preorder'; end if;
  if p_payment_provider <> 'demo' then raise exception 'Payment provider is not configured for this prototype'; end if;
  if p_payment_reference is null or length(trim(p_payment_reference))<4 then raise exception 'A prepaid payment reference is required'; end if;
  if p_pickup_date < current_date then raise exception 'Pickup date cannot be in the past'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then raise exception 'Your cart is empty'; end if;
  for row_item in select * from jsonb_array_elements(p_items) loop
    select * into menu_row from public.canteen_menu_items where id=(row_item->>'item_id')::uuid and outlet_id=outlet.id and available;
    if menu_row.id is null then raise exception 'One of the selected menu items is unavailable'; end if;
    qty:=greatest(1,(row_item->>'quantity')::integer);
    total_cost:=total_cost + menu_row.price*qty;
  end loop;
  oid:=gen_random_uuid(); code:='CC-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)); receipt:='RCPT-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)); cancel_until=now()+interval '2 minutes';
  insert into public.canteen_orders(id,student_id,outlet_id,status,total,created_at,updated_at,pickup_date,pickup_slot,notes,payment_status,payment_provider,payment_reference,cancellable_until,order_code,receipt_code)
  values(oid,auth.uid(),outlet.id,'placed',total_cost,now(),now(),p_pickup_date,p_pickup_slot,p_notes,'paid','demo',p_payment_reference,cancel_until,code,receipt);
  for row_item in select * from jsonb_array_elements(p_items) loop
    select * into menu_row from public.canteen_menu_items where id=(row_item->>'item_id')::uuid and outlet_id=outlet.id;
    qty:=greatest(1,(row_item->>'quantity')::integer);
    insert into public.canteen_order_items(order_id,item_id,quantity,unit_price) values(oid,menu_row.id,qty,menu_row.price);
  end loop;
  insert into public.audit_log(actor_id,action,entity,entity_id,metadata) values(auth.uid(),'canteen_order_placed','canteen_orders',oid,jsonb_build_object('outlet',outlet.name,'total',total_cost,'payment_reference',p_payment_reference));
  return query select oid,code,receipt,total_cost,cancel_until;
end;
$$;
revoke all on function public.place_prepaid_canteen_order(uuid,jsonb,date,text,text,text,text) from public,anon;
grant execute on function public.place_prepaid_canteen_order(uuid,jsonb,date,text,text,text,text) to authenticated;

create or replace function public.cancel_canteen_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path=''
as $$
declare o public.canteen_orders%rowtype;
begin
  select * into o from public.canteen_orders where id=p_order_id and student_id=auth.uid() for update;
  if o.id is null then raise exception 'Order not found'; end if;
  if o.status <> 'placed' then raise exception 'This order cannot be cancelled'; end if;
  if now() > o.cancellable_until then raise exception 'Cancellation window has expired. Orders can only be cancelled for 2 minutes after placement.'; end if;
  update public.canteen_orders set status='cancelled',cancelled_at=now(),updated_at=now() where id=o.id;
  insert into public.audit_log(actor_id,action,entity,entity_id) values(auth.uid(),'canteen_order_cancelled','canteen_orders',o.id);
  return true;
end;
$$;
revoke all on function public.cancel_canteen_order(uuid) from public,anon;
grant execute on function public.cancel_canteen_order(uuid) to authenticated;

create or replace function public.mark_all_notifications_read()
returns integer language plpgsql security definer set search_path='' as $$declare n integer;begin update public.notifications set is_read=true where student_id=auth.uid() and not is_read; get diagnostics n=row_count; return n;end $$;
revoke all on function public.mark_all_notifications_read() from public,anon;grant execute on function public.mark_all_notifications_read() to authenticated;

-- updated_at triggers
create or replace function public.cc_touch_updated_at() returns trigger language plpgsql set search_path='' as $$begin new.updated_at=now();return new;end$$;
drop trigger if exists lost_found_items_touch on public.lost_found_items; create trigger lost_found_items_touch before update on public.lost_found_items for each row execute function public.cc_touch_updated_at();
drop trigger if exists lost_found_claims_touch on public.lost_found_claims; create trigger lost_found_claims_touch before update on public.lost_found_claims for each row execute function public.cc_touch_updated_at();
drop trigger if exists canteen_orders_touch on public.canteen_orders; create trigger canteen_orders_touch before update on public.canteen_orders for each row execute function public.cc_touch_updated_at();

-- Official campus bodies/centres and activity-linked communities; mark their provenance in description.
insert into public.clubs(name,level,school,description,official_url) values
('USC','university',null,'University Student Council · Delhi NCR campus leadership.','https://ncr.christuniversity.in/'),
('SWO','university',null,'Student Welfare Office · cultural, welfare and volunteer activity.','https://ncr.christuniversity.in/'),
('CAPS','university',null,'Centre for Academic and Professional Support.','https://ncr.christuniversity.in/'),
('CDL','university',null,'Centre for Digital Learning.','https://ncr.christuniversity.in/'),
('CAI','university',null,'Centre for Artificial Intelligence.','https://ncr.christuniversity.in/'),
('CCHS','university',null,'Centre for Counselling and Health Services.','https://ncr.christuniversity.in/'),
('CIIC','university',null,'Innovation, incubation and impact support.','https://ncr.christuniversity.in/'),
('NCC','university',null,'National Cadet Corps · Delhi NCR.','https://ncr.christuniversity.in/'),
('Physical Education','university',null,'Physical Education, sport and recreation.','https://ncr.christuniversity.in/'),
('OIA','university',null,'Office of International Affairs.','https://ncr.christuniversity.in/'),
('CSA','university',null,'Christian Students Association.','https://ncr.christuniversity.in/')
on conflict(name) do update set description=excluded.description,official_url=excluded.official_url;
insert into public.clubs(name,level,description) values
('Christ Music Society','university','SWO cultural wing'),('Natyarpana','university','SWO university dance team'),('Cultural Team','university','SWO cultural wing'),('Debsoc','university','SWO debate society'),
('Finalytics Club','department','Activity-linked · School of Business and Management'),('Marketing Club','department','Activity-linked · School of Business and Management'),('SAMWAD Club','department','Activity-linked · School of Social Sciences'),('ECSA','department','Activity-linked · English and Cultural Studies'),('DSA / Data Science activities','department','Activity-linked · School of Sciences')
on conflict(name) do nothing;

-- Demo notification(s) for demo user, only if absent.
insert into public.notifications(student_id,title,body)
select p.id,'Welcome to Christ Connect Delhi NCR','Your private student space is connected. Demo campus tools are ready.'
from public.student_profiles p where upper(p.registration_number::text)='DEMO2026BCA001' and not exists(select 1 from public.notifications n where n.student_id=p.id and n.title='Welcome to Christ Connect Delhi NCR');

-- Notify an item owner when a new claim is submitted.
create or replace function public.notify_lost_found_owner() returns trigger language plpgsql security definer set search_path='' as $$declare owner_id uuid; item_title text;begin select i.owner_id,i.title into owner_id,item_title from public.lost_found_items i where i.id=new.item_id; if owner_id is not null and owner_id<>new.claimant_id then insert into public.notifications(student_id,title,body) values(owner_id,'New Lost & Found claim',coalesce('Someone submitted a claim for “'||item_title||'”.','A student submitted a claim.')); end if; return new;end$$;
drop trigger if exists lost_found_claim_notify on public.lost_found_claims;create trigger lost_found_claim_notify after insert on public.lost_found_claims for each row execute function public.notify_lost_found_owner();
insert into public.student_skills(student_id,skill)
select p.id,x.skill from public.student_profiles p cross join (values ('C Programming'),('Python'),('UI Design'),('Presentation')) x(skill)
where upper(p.registration_number::text)='DEMO2026BCA001' on conflict do nothing;
insert into public.student_interests(student_id,interest)
select p.id,x.interest from public.student_profiles p cross join (values ('Artificial Intelligence'),('Fitness'),('Photography'),('Campus Events')) x(interest)
where upper(p.registration_number::text)='DEMO2026BCA001' on conflict do nothing;

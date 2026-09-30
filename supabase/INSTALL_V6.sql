-- CHRIST CONNECT V6 · ONE-TIME DATABASE INSTALL
-- Run after the base supabase/schema.sql.
-- If V2, V3 and V4 were already run, use only supabase/integration_v6.sql.
-- The statements are written to be safe to re-run.



-- ================================================================
-- V2 — student profile extras
-- ================================================================
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



-- ================================================================
-- V3 — campus dining + organisations
-- ================================================================
-- CHRIST CONNECT V3 · Delhi NCR dining + pre-order layer
-- Safe migration on top of the existing schema. Does not touch Auth or server functions.

create table if not exists public.canteen_shops (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  location text,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.canteen_items add column if not exists shop_id uuid references public.canteen_shops(id) on delete set null;
alter table public.canteen_items add column if not exists description text;
alter table public.canteen_items add column if not exists prep_minutes integer not null default 10 check(prep_minutes between 0 and 240);
alter table public.canteen_orders add column if not exists shop_id uuid references public.canteen_shops(id) on delete set null;
alter table public.canteen_orders add column if not exists pickup_date date not null default current_date;
alter table public.canteen_orders add column if not exists pickup_slot text not null default '12:30 PM';
alter table public.canteen_orders add column if not exists notes text;
alter table public.canteen_orders add column if not exists order_code text;

update public.canteen_orders
set order_code = 'CC-' || upper(substr(replace(id::text,'-',''),1,8))
where order_code is null;
create unique index if not exists canteen_orders_order_code_idx on public.canteen_orders(order_code);
create index if not exists canteen_items_shop_idx on public.canteen_items(shop_id, available);
create index if not exists canteen_orders_student_created_idx on public.canteen_orders(student_id, created_at desc);

alter table public.canteen_shops enable row level security;

drop policy if exists "active canteen shops visible" on public.canteen_shops;
create policy "active canteen shops visible" on public.canteen_shops for select to authenticated using(active=true);

revoke insert, update, delete on public.canteen_orders from anon, authenticated;
revoke insert, update, delete on public.canteen_order_items from anon, authenticated;

drop policy if exists "student can create own orders" on public.canteen_orders;
drop policy if exists "student can create own order items" on public.canteen_order_items;

create or replace function public.place_canteen_preorder(
  p_shop_id uuid,
  p_pickup_date date,
  p_pickup_slot text,
  p_notes text,
  p_items jsonb
)
returns table(order_id uuid, order_code text, total numeric, shop_name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_code text;
  v_shop text;
  v_total numeric(10,2);
  v_item jsonb;
  v_item_id uuid;
  v_qty integer;
  v_price numeric(10,2);
  v_shop_id uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  if p_shop_id is null then raise exception 'Choose a dining outlet'; end if;
  if p_pickup_date < current_date then raise exception 'Pickup date cannot be in the past'; end if;
  if p_pickup_slot is null or length(trim(p_pickup_slot))=0 then raise exception 'Choose a pickup slot'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then raise exception 'Add at least one item'; end if;

  select id,name into v_shop_id,v_shop from public.canteen_shops where id=p_shop_id and active=true limit 1;
  if v_shop_id is null then raise exception 'Dining outlet is unavailable'; end if;

  v_total := 0;
  insert into public.canteen_orders(student_id,shop_id,status,total,pickup_date,pickup_slot,notes,order_code)
  values(auth.uid(),p_shop_id,'placed',0,p_pickup_date,trim(p_pickup_slot),nullif(trim(p_notes),''), 'CC-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)))
  returning id,order_code into v_order_id,v_code;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_item_id := (v_item->>'item_id')::uuid;
    v_qty := greatest(1, (v_item->>'quantity')::integer);

    select price, shop_id into v_price, v_shop_id
    from public.canteen_items
    where id=v_item_id and available=true;

    if not found or v_shop_id <> p_shop_id then
      raise exception 'One of the selected items is no longer available from this outlet';
    end if;

    insert into public.canteen_order_items(order_id,item_id,quantity,unit_price)
    values(v_order_id,v_item_id,v_qty,v_price)
    on conflict(order_id,item_id) do update set quantity=excluded.quantity,unit_price=excluded.unit_price;

    v_total := v_total + (v_price * v_qty);
  end loop;

  update public.canteen_orders set total=v_total where id=v_order_id;
  return query select v_order_id,v_code,v_total,v_shop;
end;
$$;
revoke all on function public.place_canteen_preorder(uuid,date,text,text,jsonb) from public,anon;
grant execute on function public.place_canteen_preorder(uuid,date,text,text,jsonb) to authenticated;

create or replace function public.cancel_canteen_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
begin
  update public.canteen_orders
  set status='cancelled'
  where id=p_order_id and student_id=auth.uid() and status='placed';
  return found;
end;
$$;
revoke all on function public.cancel_canteen_order(uuid) from public,anon;
grant execute on function public.cancel_canteen_order(uuid) to authenticated;

-- Campus dining outlets from the current Delhi NCR Dining Facilities page.
insert into public.canteen_shops(name,location,description) values
('Punjabi Bites','Gourmet Hall · Block A','North Indian counter'),
('Southern Delights','Gourmet Hall · Block A','South Indian counter'),
('Taste of Dilli','Gourmet Hall · Block A','Vegetarian Dilli / North Indian counter'),
('Rolls Lane','Gourmet Hall · Block A','Quick grab-and-eat counter'),
('Bites & Brews','Gourmet Hall · Block A','Cakes, wraps, burgers, beverages and ice cream'),
('Steaming Mugs','Rooftop Cafe · Block B','Cafe counter'),
('Giani’s Ice Cream','Rooftop Cafe · Block B','Ice cream outlet'),
('Domino’s','Campus outlet','Pizza and snacks'),
('Fresheteria','Block C','Fresh juices, smoothies, shakes and snacks'),
('Cafe Coffee Day','Block B · Level -1','Coffee, beverages and light bites')
on conflict(name) do update set location=excluded.location,description=excluded.description,active=true;

-- Project demo menu. These prices are placeholders for prototyping and are NOT official vendor prices.
insert into public.canteen_items(name,category,price,available,description,prep_minutes,shop_id)
select x.item_name,x.category,x.price,true,x.description,x.prep_minutes,s.id
from (values
 ('Punjabi Thali','Meals',89,'Demo North Indian thali',12,'Punjabi Bites'),
 ('Aloo Paratha','Meals',55,'Paratha served with accompaniments',8,'Punjabi Bites'),
 ('Chole Rice','Meals',69,'Rice and chickpea meal',10,'Punjabi Bites'),
 ('Masala Dosa','Meals',65,'Crisp dosa with chutney and sambar',10,'Southern Delights'),
 ('Idli Sambar','Meals',45,'Steamed idli with sambar',7,'Southern Delights'),
 ('Veg Pongal','Meals',59,'South Indian comfort meal',8,'Southern Delights'),
 ('Aloo Tikki Chaat','Snacks',49,'Dilli-style snack',8,'Taste of Dilli'),
 ('Rajma Chawal','Meals',69,'Comfort bowl',10,'Taste of Dilli'),
 ('Paneer Kathi Roll','Rolls',79,'Quick-grab paneer roll',8,'Rolls Lane'),
 ('Veg Frankie','Rolls',69,'Street-style wrap',7,'Rolls Lane'),
 ('Cold Coffee','Beverage',59,'Chilled coffee drink',6,'Bites & Brews'),
 ('Veg Burger','Snacks',79,'Classic veggie burger',9,'Bites & Brews'),
 ('Chocolate Cake Slice','Dessert',65,'Demo bakery item',5,'Bites & Brews'),
 ('Masala Tea','Beverage',25,'Hot tea',4,'Steaming Mugs'),
 ('Grilled Sandwich','Snacks',69,'Toasted veg sandwich',8,'Steaming Mugs'),
 ('Vanilla Scoop','Dessert',60,'Demo ice cream serving',3,'Giani’s Ice Cream'),
 ('Chocolate Scoop','Dessert',60,'Demo ice cream serving',3,'Giani’s Ice Cream'),
 ('Veg Pizza','Pizza',169,'Demo campus pizza item',15,'Domino’s'),
 ('Garlic Bread','Snacks',99,'Demo campus snack',10,'Domino’s'),
 ('Mango Smoothie','Beverage',69,'Fresh fruit smoothie',7,'Fresheteria'),
 ('Mixed Fruit Juice','Beverage',59,'Fresh juice',5,'Fresheteria'),
 ('Veg Sandwich','Snacks',55,'Light snack',7,'Cafe Coffee Day'),
 ('Cold Coffee','Beverage',79,'Cafe cold coffee',6,'Cafe Coffee Day')
) x(item_name,category,price,description,prep_minutes,shop_name)
join public.canteen_shops s on s.name=x.shop_name
where not exists(
  select 1 from public.canteen_items ci where ci.name=x.item_name and ci.shop_id=s.id
);

-- Replace generic old demo clubs with verified Delhi NCR student bodies/centres in a separate directory table if needed by the UI.
create table if not exists public.campus_organizations (
 id uuid primary key default gen_random_uuid(),
 code text unique not null,
 name text not null,
 kind text not null check(kind in('student-body','centre','department','office','support')),
 description text,
 official_url text,
 active boolean not null default true
);
alter table public.campus_organizations enable row level security;
drop policy if exists "campus organizations visible" on public.campus_organizations;
create policy "campus organizations visible" on public.campus_organizations for select to anon,authenticated using(active=true);

insert into public.campus_organizations(code,name,kind,description,official_url) values
('USC','University Student Council','student-body','Apex student representation body on the Delhi NCR campus.','https://ncr.christuniversity.in/support-and-assistance/Delhi%20NCR%20Campus/students-council'),
('SWO','Student Welfare Office','student-body','University student welfare platform with cultural and volunteer wings.','https://ncr.christuniversity.in/center/C/Student-Welware-office'),
('CSA','Centre for Social Action','centre','Student engagement and social action initiatives.','https://ncr.christuniversity.in/centres'),
('CAPS','Centre for Academic and Professional Support','centre','Academic/professional support, communication and workshops.','https://christuniversity.in/center/C/Student-Engagement-Centres-and-Services'),
('CDL','Centre for Digital Learning','centre','Digital learning and media initiatives.','https://ncr.christuniversity.in/centres'),
('CAI','Centre for Artificial Intelligence','centre','Responsible AI learning, research and innovation.','https://christuniversity.in/center/C/Centre-forArtificialIntelligence'),
('CIIC','Christ Innovation & Incubation Centre','centre','Innovation and incubation ecosystem.','https://ncr.christuniversity.in/centres'),
('CCHS','Centre for Counselling and Health Services','support','Counselling and health support services.','https://ncr.christuniversity.in/centres'),
('NCC','National Cadet Corps','student-body','Army Wing under the 37 Uttar Pradesh Battalion NCC.','https://ncr.christuniversity.in/center/C/ncc'),
('PE','Department of Physical Education','department','Sports and games across football, basketball, volleyball, badminton, table tennis, cricket and athletics.','https://ncr.christuniversity.in/center/C/Sports-and-Games'),
('OIA','Office of International Affairs','office','International engagement and global opportunities.','https://ncr.christuniversity.in/centres')
on conflict(code) do update set name=excluded.name,kind=excluded.kind,description=excluded.description,official_url=excluded.official_url,active=true;

-- Delhi NCR schools as directory entries.
insert into public.campus_organizations(code,name,kind,description,official_url) values
('SBM','School of Business and Management','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-business-and-management'),
('SCFA','School of Commerce, Finance and Accountancy','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-commerce-finance-and-accountancy'),
('SHPA','School of Humanities and Performing Arts','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-humanities-and-performing-arts'),
('SOL','School of Law','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-law'),
('SPS','School of Psychological Sciences','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-psychological-sciences'),
('SOS','School of Sciences','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-sciences'),
('SSS','School of Social Sciences','department','Delhi NCR school.','https://ncr.christuniversity.in/schools/school-of-social-sciences')
on conflict(code) do update set name=excluded.name,kind=excluded.kind,description=excluded.description,official_url=excluded.official_url,active=true;



-- ================================================================
-- V4 — prepaid wallet + e-receipts
-- ================================================================
-- CHRIST CONNECT V4 · prepaid pre-orders, wallet ledger, 2-minute cancel window, e-receipts
-- Run AFTER schema.sql, upgrade_v2.sql, upgrade_v3.sql. Safe to re-run.

-- 1. Wallet (prepaid balance) + append-only ledger, one wallet per registered student
create table if not exists public.student_wallets (
  student_id uuid primary key references public.student_profiles(id) on delete cascade,
  balance numeric(10,2) not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);
create table if not exists public.wallet_transactions (
  id bigint generated always as identity primary key,
  student_id uuid not null references public.student_profiles(id) on delete cascade,
  kind text not null check (kind in ('topup','order','refund')),
  amount numeric(10,2) not null,              -- + credit, - debit
  balance_after numeric(10,2) not null,
  order_id uuid references public.canteen_orders(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);
create index if not exists wallet_tx_student_idx on public.wallet_transactions(student_id, created_at desc);

-- every existing and future student automatically gets a wallet
insert into public.student_wallets(student_id) select id from public.student_profiles on conflict do nothing;
create or replace function public.create_wallet_for_student() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.student_wallets(student_id) values(new.id) on conflict do nothing; return new; end $$;
drop trigger if exists student_profiles_wallet on public.student_profiles;
create trigger student_profiles_wallet after insert on public.student_profiles for each row execute function public.create_wallet_for_student();

-- 2. Order hardening: payment state, registration number snapshot, cancel deadline
alter table public.canteen_orders add column if not exists payment_status text not null default 'paid' check (payment_status in ('paid','refunded'));
alter table public.canteen_orders add column if not exists registration_number text;
alter table public.canteen_orders add column if not exists cancel_until timestamptz;
alter table public.canteen_orders add column if not exists cancelled_at timestamptz;
alter table public.canteen_order_items add column if not exists item_name text;

-- 3. RLS: students can only READ their own wallet/ledger. All writes go through the functions below.
alter table public.student_wallets enable row level security;
alter table public.wallet_transactions enable row level security;
drop policy if exists "student reads own wallet" on public.student_wallets;
create policy "student reads own wallet" on public.student_wallets for select to authenticated using (student_id = auth.uid());
drop policy if exists "student reads own wallet tx" on public.wallet_transactions;
create policy "student reads own wallet tx" on public.wallet_transactions for select to authenticated using (student_id = auth.uid());
revoke insert, update, delete on public.student_wallets, public.wallet_transactions from anon, authenticated;

-- 4. Prepaid order placement: one transaction = lock wallet, price items server-side, debit, record.
create or replace function public.place_canteen_preorder(
  p_shop_id uuid, p_pickup_date date, p_pickup_slot text, p_notes text, p_items jsonb
) returns table(order_id uuid, order_code text, total numeric, shop_name text, cancel_until timestamptz, balance_after numeric)
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid(); v_reg text; v_shop text; v_order uuid; v_code text;
  v_total numeric(10,2) := 0; v_bal numeric(10,2); v_item jsonb; v_iid uuid; v_qty int;
  v_price numeric(10,2); v_iname text; v_ishop uuid; v_cancel timestamptz := now() + interval '2 minutes';
begin
  if v_uid is null then raise exception 'Not signed in'; end if;
  select registration_number::text into v_reg from student_profiles where id = v_uid and status = 'active';
  if v_reg is null then raise exception 'Only active registered students can order'; end if;
  select name into v_shop from canteen_shops where id = p_shop_id and active;
  if v_shop is null then raise exception 'Outlet unavailable'; end if;
  if p_pickup_date < current_date then raise exception 'Pickup date cannot be in the past'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'Add at least one item'; end if;

  select balance into v_bal from student_wallets where student_id = v_uid for update;   -- row lock: no double-spend
  if v_bal is null then raise exception 'Wallet not found'; end if;

  insert into canteen_orders(student_id, shop_id, status, total, pickup_date, pickup_slot, notes, order_code, registration_number, cancel_until, payment_status)
  values (v_uid, p_shop_id, 'placed', 0, p_pickup_date, trim(p_pickup_slot), nullif(trim(p_notes),''),
          'CC-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)), v_reg, v_cancel, 'paid')
  returning id, canteen_orders.order_code into v_order, v_code;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_iid := (v_item->>'item_id')::uuid; v_qty := greatest(1, least(20, (v_item->>'quantity')::int));
    select price, name, shop_id into v_price, v_iname, v_ishop from canteen_items where id = v_iid and available;
    if not found or v_ishop is distinct from p_shop_id then raise exception 'An item is unavailable at this outlet'; end if;
    insert into canteen_order_items(order_id, item_id, quantity, unit_price, item_name) values (v_order, v_iid, v_qty, v_price, v_iname)
      on conflict (order_id, item_id) do update set quantity = excluded.quantity;
    v_total := v_total + v_price * v_qty;
  end loop;

  if v_bal < v_total then raise exception 'Insufficient wallet balance (need ₹%, have ₹%)', v_total, v_bal; end if;
  update student_wallets set balance = balance - v_total, updated_at = now() where student_id = v_uid returning balance into v_bal;
  update canteen_orders set total = v_total where id = v_order;
  insert into wallet_transactions(student_id, kind, amount, balance_after, order_id, note)
    values (v_uid, 'order', -v_total, v_bal, v_order, v_shop || ' · ' || v_code);
  insert into audit_log(actor_id, action, entity, entity_id, metadata)
    values (v_uid, 'order.placed', 'canteen_orders', v_order, jsonb_build_object('total', v_total, 'shop', v_shop));
  return query select v_order, v_code, v_total, v_shop, v_cancel, v_bal;
end $$;
revoke all on function public.place_canteen_preorder(uuid,date,text,text,jsonb) from public, anon;
grant execute on function public.place_canteen_preorder(uuid,date,text,text,jsonb) to authenticated;

-- 5. Cancel: only the owner, only status 'placed', only before cancel_until (server clock decides). Full refund.
create or replace function public.cancel_canteen_order(p_order_id uuid) returns boolean
language plpgsql security definer set search_path = public as $$
declare v_o canteen_orders%rowtype; v_bal numeric(10,2);
begin
  select * into v_o from canteen_orders where id = p_order_id and student_id = auth.uid() for update;
  if not found then raise exception 'Order not found'; end if;
  if v_o.status <> 'placed' then raise exception 'Order can no longer be cancelled'; end if;
  if now() > v_o.cancel_until then raise exception 'The 2-minute cancellation window has closed'; end if;
  update canteen_orders set status = 'cancelled', payment_status = 'refunded', cancelled_at = now() where id = p_order_id;
  update student_wallets set balance = balance + v_o.total, updated_at = now() where student_id = v_o.student_id returning balance into v_bal;
  insert into wallet_transactions(student_id, kind, amount, balance_after, order_id, note)
    values (v_o.student_id, 'refund', v_o.total, v_bal, p_order_id, 'Cancelled ' || v_o.order_code);
  return true;
end $$;
revoke all on function public.cancel_canteen_order(uuid) from public, anon;
grant execute on function public.cancel_canteen_order(uuid) to authenticated;

-- 6. E-receipt as one JSON document (shown on the website only). Owner-only.
create or replace function public.get_order_receipt(p_order_id uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'order_code', o.order_code, 'status', o.status, 'payment_status', o.payment_status,
    'registration_number', o.registration_number, 'student_name', p.full_name,
    'outlet', s.name, 'location', s.location, 'placed_at', o.created_at, 'cancel_until', o.cancel_until,
    'pickup_date', o.pickup_date, 'pickup_slot', o.pickup_slot, 'total', o.total, 'notes', o.notes,
    'items', coalesce((select jsonb_agg(jsonb_build_object('name', coalesce(i.item_name, ci.name), 'qty', i.quantity, 'unit_price', i.unit_price, 'line_total', i.quantity * i.unit_price))
                       from canteen_order_items i left join canteen_items ci on ci.id = i.item_id where i.order_id = o.id), '[]'::jsonb))
  from canteen_orders o join student_profiles p on p.id = o.student_id left join canteen_shops s on s.id = o.shop_id
  where o.id = p_order_id and o.student_id = auth.uid();
$$;
revoke all on function public.get_order_receipt(uuid) from public, anon;
grant execute on function public.get_order_receipt(uuid) to authenticated;

-- 7. Wallet top-up is ADMIN-ONLY (run from SQL editor / service role after the student pays at the accounts counter).
--    Example: select public.admin_topup_wallet('DEMO2026BCA001', 500, 'Counter payment #123');
create or replace function public.admin_topup_wallet(p_registration text, p_amount numeric, p_note text default null) returns numeric
language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_bal numeric(10,2);
begin
  if p_amount <= 0 then raise exception 'Amount must be positive'; end if;
  select id into v_id from student_profiles where registration_number = p_registration::citext;
  if v_id is null then raise exception 'No student with that registration number'; end if;
  update student_wallets set balance = balance + p_amount, updated_at = now() where student_id = v_id returning balance into v_bal;
  insert into wallet_transactions(student_id, kind, amount, balance_after, note) values (v_id, 'topup', p_amount, v_bal, p_note);
  return v_bal;
end $$;
revoke all on function public.admin_topup_wallet(text,numeric,text) from public, anon, authenticated;

-- Demo wallet credit for the demo account only (remove for production)
do $$ begin perform public.admin_topup_wallet('DEMO2026BCA001', 1000, 'Demo credit'); exception when others then null; end $$;



-- ================================================================
-- V6 — live website integration + lost & found
-- ================================================================

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


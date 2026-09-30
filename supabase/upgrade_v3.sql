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

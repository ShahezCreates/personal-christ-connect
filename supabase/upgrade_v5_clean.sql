-- CHRIST CONNECT V5 (clean rewrite of v4) · prepaid pre-orders, wallet ledger, 2-minute cancel window, e-receipts
-- Run AFTER schema.sql, upgrade_v2.sql, upgrade_v3.sql. Safe to re-run.

-- 0. Remove every older overload of these functions (v3 returned a different shape -> "cannot change return type" error)
do $$ declare r record; begin
  for r in select p.oid::regprocedure as sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='public' and p.proname in ('place_canteen_preorder','cancel_canteen_order','get_order_receipt','admin_topup_wallet')
  loop execute 'drop function if exists '||r.sig||' cascade'; end loop; end $$;

-- Needed for citext comparisons
create extension if not exists citext;

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
language plpgsql security definer set search_path = public as $fn$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid(); v_reg text; v_shop text; v_order uuid; v_code text;
  v_total numeric(10,2) := 0; v_bal numeric(10,2); v_row record; v_price numeric(10,2); v_iname text; v_ishop uuid;
  v_cancel timestamptz := now() + interval '2 minutes';
begin
  if v_uid is null then raise exception 'Not signed in'; end if;
  select sp.registration_number::text into v_reg from student_profiles sp where sp.id = v_uid and sp.status = 'active';
  if v_reg is null then raise exception 'Only active registered students can order'; end if;
  select cs.name into v_shop from canteen_shops cs where cs.id = p_shop_id and cs.active;
  if v_shop is null then raise exception 'Outlet unavailable'; end if;
  if p_pickup_date < current_date then raise exception 'Pickup date cannot be in the past'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'Add at least one item'; end if;

  select w.balance into v_bal from student_wallets w where w.student_id = v_uid for update;
  if v_bal is null then raise exception 'Wallet not found'; end if;

  v_code := 'CC-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
  insert into canteen_orders(student_id, shop_id, status, total, pickup_date, pickup_slot, notes, order_code, registration_number, cancel_until, payment_status)
  values (v_uid, p_shop_id, 'placed', 0, p_pickup_date, trim(p_pickup_slot), nullif(trim(p_notes),''), v_code, v_reg, v_cancel, 'paid')
  returning canteen_orders.id into v_order;

  for v_row in select (e->>'item_id')::uuid as iid, least(20, greatest(1, sum((e->>'quantity')::int)))::int as qty
               from jsonb_array_elements(p_items) e group by 1 loop
    select ci.price, ci.name, ci.shop_id into v_price, v_iname, v_ishop from canteen_items ci where ci.id = v_row.iid and ci.available;
    if v_price is null or v_ishop is distinct from p_shop_id then raise exception 'An item is unavailable at this outlet'; end if;
    insert into canteen_order_items(order_id, item_id, quantity, unit_price, item_name) values (v_order, v_row.iid, v_row.qty, v_price, v_iname);
    v_total := v_total + v_price * v_row.qty;
  end loop;

  if v_bal < v_total then raise exception 'Insufficient wallet balance (need Rs %, have Rs %)', v_total, v_bal; end if;
  update student_wallets w set balance = w.balance - v_total, updated_at = now() where w.student_id = v_uid returning w.balance into v_bal;
  update canteen_orders o set total = v_total where o.id = v_order;
  insert into wallet_transactions(student_id, kind, amount, balance_after, order_id, note) values (v_uid, 'order', -v_total, v_bal, v_order, v_shop || ' - ' || v_code);
  insert into audit_log(actor_id, action, entity, entity_id, metadata) values (v_uid, 'order.placed', 'canteen_orders', v_order, jsonb_build_object('total', v_total, 'shop', v_shop));
  return query select v_order, v_code, v_total, v_shop, v_cancel, v_bal;
end $fn$;
revoke all on function public.place_canteen_preorder(uuid,date,text,text,jsonb) from public, anon;
grant execute on function public.place_canteen_preorder(uuid,date,text,text,jsonb) to authenticated;

-- 5. Cancel: only the owner, only status 'placed', only before cancel_until (server clock decides). Full refund.
create or replace function public.cancel_canteen_order(p_order_id uuid) returns boolean
language plpgsql security definer set search_path = public as $c$
#variable_conflict use_column
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
end $c$;
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
language plpgsql security definer set search_path = public as $t$
#variable_conflict use_column
declare v_id uuid; v_bal numeric(10,2);
begin
  if p_amount <= 0 then raise exception 'Amount must be positive'; end if;
  select id into v_id from student_profiles where registration_number = p_registration::citext;
  if v_id is null then raise exception 'No student with that registration number'; end if;
  update student_wallets set balance = balance + p_amount, updated_at = now() where student_id = v_id returning balance into v_bal;
  insert into wallet_transactions(student_id, kind, amount, balance_after, note) values (v_id, 'topup', p_amount, v_bal, p_note);
  return v_bal;
end $t$;
revoke all on function public.admin_topup_wallet(text,numeric,text) from public, anon, authenticated;

-- Demo wallet credit for the demo account only (remove for production)
do $$ begin perform public.admin_topup_wallet('DEMO2026BCA001', 1000, 'Demo credit'); exception when others then null; end $$;

-- 8. Departments & clubs (only facts published on ncr.christuniversity.in)
create table if not exists public.departments (
  id serial primary key, school text not null, name text not null unique, hod text, summary text, programmes text[] not null default '{}');
create table if not exists public.clubs (
  id serial primary key, name text not null unique, level text not null check (level in ('university','school','department')),
  department_id int references public.departments(id) on delete set null, instagram text, about text, founded smallint);
alter table public.departments enable row level security; alter table public.clubs enable row level security;
drop policy if exists "public reads departments" on public.departments; create policy "public reads departments" on public.departments for select using (true);
drop policy if exists "public reads clubs" on public.clubs; create policy "public reads clubs" on public.clubs for select using (true);

insert into public.departments(school,name,hod,summary,programmes) values
('School of Sciences','Computational Sciences (Computer Science, Mathematics & Statistics)','Dr. Bosco Paul Alapatt',
 'Delhi NCR wing of the School of Sciences, with a dedicated research block. Offers undergraduate and doctoral programmes in Computer Science, Mathematics and Statistics.',
 array['BCA (Honours / Honours with Research)','BSc Data Science and Artificial Intelligence (Honours)','BSc Computer Science, Mathematics, Statistics','BSc Economics, Mathematics, Statistics','BSc Economics, Data Analytics (Honours)','PhD Computer Science','PhD Mathematics']),
('School of Arts, Humanities and Social Sciences','Arts, Humanities & Social Sciences',null,
 'Humanities and social-science programmes on the Delhi NCR campus.',
 array['BA Economics, Political Science, Sociology','BA Psychology, Sociology, English','BA Media and Public Affairs (Honours)','BSc Psychology (Honours)','BSc Economics (Honours)'])
on conflict (name) do nothing;
insert into public.clubs(name,level,department_id,instagram,about,founded) values
('Student Council NCR','university',null,'studentcouncil_ncr','Official student council of CHRIST Delhi NCR Campus.',null),
('EULIM Science Club','school',(select id from public.departments where school='School of Sciences'),null,'Formed by the School of Sciences for technical and co-curricular activity, independent research and self-expression.',null),
('Technical Club of Sciences (TCS)','school',(select id from public.departments where school='School of Sciences'),null,'Intra-departmental technical club focused on technical skills, placement preparation and competitions.',2023),
('Department Sports Club','school',(select id from public.departments where school='School of Sciences'),null,'Intra-departmental sports cell running sports activities through the year.',2021)
on conflict (name) do nothing;

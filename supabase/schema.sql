create extension if not exists pgcrypto;

create table if not exists public.departments (
  id bigint generated always as identity primary key,
  name character varying not null,
  description text,
  created_at timestamp without time zone default now()
);

comment on table public.departments is
  'Access departments: id 1 = owner, id 2 = employee (no management access), id 3 = admin (own branch only).';

create table if not exists public.positions (
  id bigint generated always as identity primary key,
  department_id bigint references public.departments(id),
  name character varying,
  salary numeric,
  created_at timestamp without time zone default now()
);

create table if not exists public.branches (
  id bigint generated always as identity primary key,
  branch_code varchar(10) unique not null,
  branch_name varchar(100) not null,
  address text,
  phone varchar(20),
  manager_name varchar(100),
  status varchar(20) default 'Active',
  created_at timestamp without time zone default now()
);

create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  employee_code character varying unique,
  first_name character varying,
  last_name character varying,
  gender character varying,
  phone character varying,
  email character varying,
  birth_date date,
  address text,
  branch_id bigint references public.branches(id),
  department_id bigint references public.departments(id),
  position_id bigint references public.positions(id),
  hire_date date,
  status character varying default 'Active',
  profile_image text,
  created_at timestamp without time zone default now()
);

-- Keeps existing installations compatible with the new branches table.
alter table public.employees
  add column if not exists branch_id bigint references public.branches(id);

create table if not exists public.attendance (
  id bigint generated always as identity primary key,
  employee_id uuid references public.employees(id),
  check_in timestamp without time zone,
  check_out timestamp without time zone,
  work_date date,
  status character varying,
  note text
);

create table if not exists public.customers (
  id bigint generated always as identity primary key,
  customer_code varchar(20) unique not null,
  first_name varchar(100) not null,
  last_name varchar(100) not null,
  gender varchar(10),
  phone varchar(20) unique,
  email varchar(100),
  birth_date date,
  address text,
  member_level varchar(30) default 'Silver',
  points integer default 0,
  branch_id bigint references public.branches(id),
  created_at timestamp without time zone default now()
);

create table if not exists public.leave_type (
  id bigint generated always as identity primary key,
  name character varying
);

create table if not exists public.leave_requests (
  id bigint generated always as identity primary key,
  employee_id uuid references public.employees(id),
  leave_type_id bigint references public.leave_type(id),
  start_date date,
  end_date date,
  reason text,
  status character varying default 'Pending',
  created_at timestamp without time zone default now()
);

create table if not exists public.payroll (
  id bigint generated always as identity primary key,
  employee_id uuid references public.employees(id),
  month integer,
  year integer,
  basic_salary numeric,
  overtime numeric,
  bonus numeric,
  deduction numeric,
  total_salary numeric,
  payment_date date
);

create table if not exists public.announcements (
  id bigint generated always as identity primary key,
  title character varying,
  detail text,
  created_at timestamp without time zone default now()
);

create table if not exists public.services (
  id bigint generated always as identity primary key,
  name character varying,
  price numeric
);

create table if not exists public.service_history (
  id bigint generated always as identity primary key,
  employee_id uuid references public.employees(id),
  customer_id bigint references public.customers(id),
  service_id bigint references public.services(id),
  customer_name character varying,
  price numeric,
  commission numeric,
  service_date timestamp without time zone default now()
);

alter table public.service_history
  add column if not exists customer_id bigint references public.customers(id);

create table if not exists public.commission (
  id bigint generated always as identity primary key,
  employee_id uuid references public.employees(id),
  month integer,
  year integer,
  total_sales numeric,
  commission_percent numeric,
  commission_amount numeric
);

insert into public.departments(name)
values
  ('IT'),
  ('HR'),
  ('Accounting'),
  ('Sales'),
  ('Marketing')
on conflict do nothing;

insert into public.branches(branch_code, branch_name, address, phone, manager_name)
values
  ('B001', 'สาขาเซ็นทรัลเวิลด์', 'กรุงเทพมหานคร', '021111111', 'สมหญิง'),
  ('B002', 'สาขาสยาม', 'กรุงเทพมหานคร', '022222222', 'แอน'),
  ('B003', 'สาขาฟิวเจอร์พาร์ค รังสิต', 'ปทุมธานี', '023333333', 'น้ำ')
on conflict (branch_code) do nothing;

insert into public.customers
  (customer_code, first_name, last_name, gender, phone, email, birth_date, address, member_level, points, branch_id)
values
  ('CUS001', 'ศศิ', 'ทองดี', 'Female', '0891111111', 'sasi@email.com', '1998-02-15', 'กรุงเทพ', 'Gold', 150, 1),
  ('CUS002', 'พรทิพย์', 'สุขใจ', 'Female', '0892222222', 'pornthip@email.com', '1996-05-22', 'นนทบุรี', 'Silver', 80, 1),
  ('CUS003', 'อรทัย', 'แสงแก้ว', 'Female', '0893333333', 'ornthai@email.com', '1995-09-18', 'ปทุมธานี', 'Platinum', 420, 2),
  ('CUS004', 'วิภา', 'ใจดี', 'Female', '0894444444', 'wipa@email.com', '1999-12-03', 'สมุทรปราการ', 'Silver', 30, 2),
  ('CUS005', 'กนกวรรณ', 'รุ่งเรือง', 'Female', '0895555555', 'kanok@email.com', '1997-11-25', 'กรุงเทพ', 'Gold', 210, 3),
  ('CUS006', 'สุภาวดี', 'บุญมี', 'Female', '0896666666', 'supawadee@email.com', '1994-04-11', 'นครปฐม', 'Silver', 60, 3),
  ('CUS007', 'ชลธิชา', 'สายทอง', 'Female', '0897777777', 'chon@email.com', '2001-01-08', 'กรุงเทพ', 'Gold', 175, 1),
  ('CUS008', 'ณัฐธิดา', 'วงศ์ดี', 'Female', '0898888888', 'nat@email.com', '2000-08-14', 'นนทบุรี', 'Silver', 40, 2),
  ('CUS009', 'รัตนา', 'พูนสุข', 'Female', '0899999999', 'rat@email.com', '1993-03-19', 'กรุงเทพ', 'Platinum', 650, 3),
  ('CUS010', 'อัญชลี', 'ศรีสุข', 'Female', '0881111111', 'anchalee@email.com', '1998-07-10', 'ปทุมธานี', 'Gold', 120, 1)
on conflict (customer_code) do nothing;

insert into public.positions(department_id, name, salary)
values
  (1, 'Programmer', 35000),
  (1, 'Senior Programmer', 50000),
  (2, 'HR Officer', 28000),
  (3, 'Accountant', 30000),
  (4, 'Sales Executive', 25000),
  (5, 'Marketing Officer', 27000)
on conflict do nothing;

insert into public.leave_type(name)
values
  ('Sick Leave'),
  ('Vacation Leave'),
  ('Personal Leave'),
  ('Maternity Leave')
on conflict do nothing;

insert into public.services(name, price)
values
  ('Consulting', 2500),
  ('Implementation', 8000),
  ('Training', 3500)
on conflict do nothing;

insert into public.announcements(title, detail)
values
  ('Company Meeting', 'Monthly company meeting'),
  ('Bonus payment on 25th', 'Bonus will be paid with this salary cycle')
on conflict do nothing;

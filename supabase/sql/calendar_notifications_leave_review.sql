-- Calendar entries for work schedules, holidays, and employee leave.
create table if not exists public.calendar_events (
  id bigint generated always as identity primary key,
  title varchar(150) not null,
  detail text,
  event_type varchar(30) default 'Work',
  start_date date not null,
  end_date date not null,
  branch_id bigint references public.branches(id),
  employee_id uuid references public.employees(id),
  created_at timestamp without time zone default now()
);

-- In-app notifications. A null employee_id means the notification is visible
-- to every employee, for example a company-wide announcement.
create table if not exists public.notifications (
  id bigint generated always as identity primary key,
  employee_id uuid references public.employees(id),
  title varchar(150) not null,
  message text,
  notification_type varchar(30) default 'General',
  is_read boolean default false,
  created_at timestamp without time zone default now()
);

-- Leave approval audit fields.
alter table public.leave_requests
  add column if not exists reviewed_by uuid references public.employees(id);

alter table public.leave_requests
  add column if not exists reviewed_at timestamp without time zone;

alter table public.leave_requests
  add column if not exists review_note text;

-- Indexes used by calendar and notification list queries.
create index if not exists calendar_events_branch_start_idx
  on public.calendar_events (branch_id, start_date);

create index if not exists notifications_employee_created_idx
  on public.notifications (employee_id, created_at desc);

create index if not exists leave_requests_status_created_idx
  on public.leave_requests (status, created_at desc);

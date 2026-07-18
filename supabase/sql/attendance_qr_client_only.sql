-- Client-only QR + GPS attendance (does not require Edge Function deployment).
alter table public.branches
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists attendance_radius_m integer not null default 100;

create table if not exists public.attendance_qr_sessions (
  id uuid primary key default gen_random_uuid(),
  branch_id bigint not null references public.branches(id) on delete cascade,
  token uuid not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.attendance
  add column if not exists qr_session_id uuid references public.attendance_qr_sessions(id),
  add column if not exists check_in_latitude double precision,
  add column if not exists check_in_longitude double precision,
  add column if not exists check_in_distance_m numeric,
  add column if not exists check_out_latitude double precision,
  add column if not exists check_out_longitude double precision,
  add column if not exists check_out_distance_m numeric;

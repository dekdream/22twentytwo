-- Run this once in Supabase SQL Editor for an existing project.
-- Base salary is stored per employee and becomes the payroll default.
alter table public.employees
  add column if not exists base_salary numeric not null default 0;

-- Ask PostgREST to immediately reload the table definition.
notify pgrst, 'reload schema';

-- Required only if RLS is disabled and the app is using the anon key in the
-- current client-only QR trial mode.
grant select, insert, update, delete on table public.attendance_qr_sessions to anon;

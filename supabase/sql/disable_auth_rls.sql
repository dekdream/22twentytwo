-- Revert the Auth/RLS rollout without deleting employee or Auth data.
begin;

do $$
declare table_record record;
begin
  for table_record in
    select tablename from pg_tables where schemaname = 'public'
  loop
    execute format('alter table public.%I disable row level security', table_record.tablename);
  end loop;
end $$;

do $$
declare policy_record record;
begin
  for policy_record in
    select schemaname, tablename, policyname
      from pg_policies
     where schemaname = 'public' and policyname like 'app_%'
  loop
    execute format('drop policy %I on %I.%I', policy_record.policyname,
                   policy_record.schemaname, policy_record.tablename);
  end loop;
end $$;

drop policy if exists app_profile_insert on storage.objects;
drop policy if exists app_profile_update on storage.objects;
drop policy if exists app_profile_delete on storage.objects;

-- Restore direct client access used by the original app.
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

notify pgrst, 'reload schema';
commit;

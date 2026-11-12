-- Reps 100: one-time setup for a Supabase project.
-- Run the whole file once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.

-- One row per user holding the whole app state.
create table if not exists public.reps_state (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.reps_state enable row level security;

drop policy if exists "reps_state own row" on public.reps_state;
create policy "reps_state own row" on public.reps_state
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Private bucket for progress photos and the voice memo. Each user only reaches their own folder.
insert into storage.buckets (id, name, public)
values ('reps', 'reps', false)
on conflict (id) do nothing;

drop policy if exists "reps files select" on storage.objects;
create policy "reps files select" on storage.objects
  for select to authenticated
  using (bucket_id = 'reps' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "reps files insert" on storage.objects;
create policy "reps files insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'reps' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "reps files update" on storage.objects;
create policy "reps files update" on storage.objects
  for update to authenticated
  using (bucket_id = 'reps' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'reps' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "reps files delete" on storage.objects;
create policy "reps files delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'reps' and (storage.foldername(name))[1] = (select auth.uid())::text);

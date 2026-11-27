create table if not exists public.shares (
  id text primary key check (char_length(id) between 6 and 16),
  data text not null check (char_length(data) between 3 and 100000),
  created_at timestamptz not null default now()
);
alter table public.shares enable row level security;

drop policy if exists "shares_read" on public.shares;
create policy "shares_read" on public.shares for select to anon, authenticated using (true);

drop policy if exists "shares_write" on public.shares;
create policy "shares_write" on public.shares for insert to anon, authenticated with check (true);

revoke all on public.shares from anon, authenticated;
grant select (id, data) on public.shares to anon, authenticated;
grant insert (id, data) on public.shares to anon, authenticated;

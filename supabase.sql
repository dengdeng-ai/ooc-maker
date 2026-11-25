create table if not exists public.posts (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  title text not null check (char_length(title) between 1 and 60),
  body text not null check (char_length(body) between 1 and 20000),
  adult boolean not null default false,
  locked boolean not null default false,
  del_hash text not null check (char_length(del_hash) = 64),
  constraint adult_needs_password check (not adult or locked)
);

alter table public.posts enable row level security;

drop policy if exists "posts_read" on public.posts;
create policy "posts_read" on public.posts for select to anon, authenticated using (true);

drop policy if exists "posts_write" on public.posts;
create policy "posts_write" on public.posts for insert to anon, authenticated with check (true);

revoke all on public.posts from anon, authenticated;
grant select (id, created_at, title, body, adult, locked) on public.posts to anon, authenticated;
grant insert (title, body, adult, locked, del_hash) on public.posts to anon, authenticated;

create or replace function public.delete_post(pid bigint, token text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  delete from public.posts
  where id = pid and del_hash = encode(sha256(convert_to(token, 'UTF8')), 'hex');
  get diagnostics n = row_count;
  return n > 0;
end
$$;

revoke all on function public.delete_post(bigint, text) from public;
grant execute on function public.delete_post(bigint, text) to anon, authenticated;

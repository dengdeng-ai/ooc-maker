alter table public.posts add column if not exists downloads int not null default 0;
create index if not exists posts_downloads_idx on public.posts (downloads desc, id desc);

grant select (downloads) on public.posts to anon, authenticated;

create or replace function public.bump_download(pid bigint)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts set downloads = downloads + 1 where id = pid;
$$;
revoke all on function public.bump_download(bigint) from public;
grant execute on function public.bump_download(bigint) to anon, authenticated;

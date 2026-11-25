alter table public.posts add column if not exists reports int not null default 0;

create table if not exists public.post_reports (
  post_id bigint not null references public.posts(id) on delete cascade,
  reporter text not null check (char_length(reporter) between 8 and 64),
  created_at timestamptz not null default now(),
  primary key (post_id, reporter)
);
alter table public.post_reports enable row level security;
revoke all on public.post_reports from anon, authenticated;

create table if not exists public.banned_words (
  word text primary key check (char_length(word) between 1 and 50)
);
alter table public.banned_words enable row level security;
revoke all on public.banned_words from anon, authenticated;

drop policy if exists "posts_read" on public.posts;
create policy "posts_read" on public.posts for select to anon, authenticated using (reports < 3);

create or replace function public.report_post(pid bigint, reporter text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.post_reports (post_id, reporter) values (pid, reporter)
  on conflict do nothing;
  if not found then
    return false;
  end if;
  update public.posts set reports = reports + 1 where id = pid;
  return true;
end
$$;
revoke all on function public.report_post(bigint, text) from public;
grant execute on function public.report_post(bigint, text) to anon, authenticated;

create or replace function public.check_banned_words()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.banned_words b
    where position(lower(b.word) in lower(new.title)) > 0
       or (not new.locked and position(lower(b.word) in lower(new.body)) > 0)
  ) then
    raise exception 'banned';
  end if;
  return new;
end
$$;

drop trigger if exists posts_banned_words on public.posts;
create trigger posts_banned_words
before insert on public.posts
for each row execute function public.check_banned_words();

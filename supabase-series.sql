alter table public.posts add column if not exists count smallint not null default 1;

alter table public.posts drop constraint if exists posts_count_check;
alter table public.posts add constraint posts_count_check check (count between 1 and 30);

alter table public.posts drop constraint if exists posts_body_check;
alter table public.posts add constraint posts_body_check check (char_length(body) between 1 and 60000);

grant select (count) on public.posts to anon, authenticated;
grant insert (count) on public.posts to anon, authenticated;

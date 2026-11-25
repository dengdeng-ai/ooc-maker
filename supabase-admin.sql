create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

drop policy if exists "posts_read" on public.posts;
create policy "posts_read" on public.posts for select to anon, authenticated
  using (reports < 3 or public.is_admin());

drop policy if exists "posts_admin_delete" on public.posts;
create policy "posts_admin_delete" on public.posts for delete to authenticated
  using (public.is_admin());

drop policy if exists "posts_admin_update" on public.posts;
create policy "posts_admin_update" on public.posts for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select (reports) on public.posts to authenticated;
grant update (reports) on public.posts to authenticated;
grant delete on public.posts to authenticated;

insert into public.admins (user_id)
select id from auth.users where email = '여기에_관리자_이메일'
on conflict do nothing;

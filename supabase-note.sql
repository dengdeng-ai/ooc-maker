alter table public.posts add column if not exists note text;

alter table public.posts drop constraint if exists posts_note_check;
alter table public.posts add constraint posts_note_check check (note is null or char_length(note) <= 100);

grant select (note) on public.posts to anon, authenticated;
grant insert (note) on public.posts to anon, authenticated;

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
       or position(lower(b.word) in lower(coalesce(new.note, ''))) > 0
       or (not new.locked and position(lower(b.word) in lower(new.body)) > 0)
  ) then
    raise exception 'banned';
  end if;
  return new;
end
$$;

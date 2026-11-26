create or replace function public.update_post(pid bigint, token text, new_title text, new_body text, new_note text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  update public.posts
  set title = new_title, body = new_body, note = nullif(new_note, '')
  where id = pid and del_hash = encode(sha256(convert_to(token, 'UTF8')), 'hex');
  get diagnostics n = row_count;
  return n > 0;
end
$$;
revoke all on function public.update_post(bigint, text, text, text, text) from public;
grant execute on function public.update_post(bigint, text, text, text, text) to anon, authenticated;

drop trigger if exists posts_banned_words on public.posts;
create trigger posts_banned_words
before insert or update of title, body, note on public.posts
for each row execute function public.check_banned_words();

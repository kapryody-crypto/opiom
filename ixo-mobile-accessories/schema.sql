create table if not exists public.ixo_catalog (
 id integer primary key default 1 check (id = 1),
 phones jsonb not null default '[]'::jsonb check (jsonb_typeof(phones)='array'),
 updated_at timestamptz not null default now(),
 version bigint not null default 1
);
alter table public.ixo_catalog enable row level security;
grant select on public.ixo_catalog to anon, authenticated;
grant update on public.ixo_catalog to authenticated;
create policy "Public can view IXO catalog" on public.ixo_catalog for select to anon, authenticated using (true);
create policy "OPIOM owners can update IXO catalog" on public.ixo_catalog for update to authenticated using (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.active=true and p.role in ('owner','admin'))) with check (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.active=true and p.role in ('owner','admin')));
insert into public.ixo_catalog(id,phones,updated_at,version) values (1,'[{"brand":"Bebe Tab","model":"Bebe Tab B88 mill","spec":"128/4 Go","cond":"Neuf","stock":true,"price":37000},{"brand":"Bebe Tab","model":"Bebe Tab B2050","spec":"128/4 Go","cond":"Neuf","stock":true,"price":42500},{"brand":"Bebe Tab","model":"Bebe Tab Bebe tech","spec":"128/4 Go","cond":"Neuf","stock":true,"price":42500},{"brand":"Google Pixel","model":"Google Pixel 7","spec":"128/8 Go","cond":"Occasion","stock":true,"price":145000},{"brand":"Honor","model":"Honor X7b","spec":"128/8 Go","cond":"Neuf","stock":true,"price":78000},{"brand":"Huawei","model":"Huawei Nova Y61","spec":"64/4 Go","cond":"Neuf","stock":false,"price":62000},{"brand":"Samsung","model":"Samsung Galaxy A15","spec":"128/4 Go","cond":"Neuf","stock":true,"price":72500},{"brand":"Xiaomi","model":"Redmi 13C","spec":"128/4 Go","cond":"Neuf","stock":true,"price":59000}]'::jsonb,'2026-10-24 00:57:00'::timestamptz,1) on conflict (id) do nothing;
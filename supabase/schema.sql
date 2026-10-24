-- OPIOM workspace: exécuter dans Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 role text not null default 'member' check (role in ('owner','admin','manager','member')),
 active boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.workspace_data (
 key text primary key check (key in ('opiom:projects','opiom:clients','opiom:team','opiom:demandes','opiom:activity')),
 value jsonb not null default '[]'::jsonb,
 updated_at timestamptz not null default now()
);
create table if not exists public.audit_events (
 id bigint generated always as identity primary key,
 actor uuid not null references auth.users(id),
 action text not null,
 created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.workspace_data enable row level security;
alter table public.audit_events enable row level security;
create or replace function public.is_active_member() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and active);
$$;
create or replace function public.has_workspace_role(roles text[]) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and active and role=any(roles));
$$;
drop policy if exists "members read profiles" on public.profiles;
create policy "members read profiles" on public.profiles for select to authenticated using (public.is_active_member());
drop policy if exists "admins manage profiles" on public.profiles;
create policy "admins manage profiles" on public.profiles for update to authenticated using (public.has_workspace_role(array['owner','admin'])) with check (public.has_workspace_role(array['owner','admin']) and role <> 'owner');
drop policy if exists "members read data" on public.workspace_data;
create policy "members read data" on public.workspace_data for select to authenticated using (public.is_active_member());
drop policy if exists "staff write data" on public.workspace_data;
create policy "staff write data" on public.workspace_data for insert to authenticated with check (public.has_workspace_role(array['owner','admin','manager','member']) and key <> 'opiom:team');
drop policy if exists "staff update data" on public.workspace_data;
create policy "staff update data" on public.workspace_data for update to authenticated using (public.is_active_member() and (key <> 'opiom:team' or public.has_workspace_role(array['owner','admin']))) with check (public.is_active_member() and (key <> 'opiom:team' or public.has_workspace_role(array['owner','admin'])));
drop policy if exists "members read audit" on public.audit_events;
create policy "members read audit" on public.audit_events for select to authenticated using (public.is_active_member());
drop policy if exists "members add audit" on public.audit_events;
create policy "members add audit" on public.audit_events for insert to authenticated with check (actor=auth.uid() and public.is_active_member());
-- Création de profil à l'inscription (désactivé tant qu'un administrateur ne valide pas).
create or replace function public.new_user_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,display_name,role,active)
 values(new.id,coalesce(new.raw_user_meta_data->>'display_name',''),'member',false);
 return new;
end; $$;
drop trigger if exists on_auth_user_created_opiom on auth.users;
create trigger on_auth_user_created_opiom after insert on auth.users for each row execute function public.new_user_profile();
-- IMPORTANT: après création du premier compte, promouvoir manuellement via SQL Editor :
-- update public.profiles set role='owner', active=true where id=(select id from auth.users where email='VOTRE_EMAIL');
-- Pour inviter des collaborateurs: créer les utilisateurs dans Supabase Auth puis activer leur profil.

revoke all on function public.is_active_member() from public, anon;
revoke all on function public.has_workspace_role(text[]) from public, anon;
grant execute on function public.is_active_member() to authenticated;
grant execute on function public.has_workspace_role(text[]) to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.workspace_data to authenticated;
grant select, insert on public.audit_events to authenticated;

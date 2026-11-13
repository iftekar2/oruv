-- ============================================================================
-- ORUV SUPABASE DATABASE SCHEMA
-- Run this script in your Supabase SQL Editor (https://supabase.com/dashboard)
-- ============================================================================

-- 1. USER PROFILES TABLE (Create or upgrade existing table)
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  email text,
  avatar_url text,
  age integer,
  focus_priority text default 'Deep Work & Career Focus',
  daily_screen_time text default '3 - 4 hours',
  screen_time_authorized boolean default false,
  selected_apps_count integer default 0,
  selected_categories_count integer default 0,
  selected_domains_count integer default 0,
  selected_categories text[] default '{}',
  selected_apps text[] default '{}',
  schedule_start text default '9:00 AM',
  schedule_end text default '5:00 PM',
  active_days text[] default array['M', 'T', 'W', 'T2', 'F'],
  strict_lock boolean default true,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

-- Safely add columns if public.profiles already existed with fewer columns
alter table public.profiles add column if not exists age integer;
alter table public.profiles add column if not exists focus_priority text default 'Deep Work & Career Focus';
alter table public.profiles add column if not exists daily_screen_time text default '3 - 4 hours';
alter table public.profiles add column if not exists screen_time_authorized boolean default false;
alter table public.profiles add column if not exists selected_apps_count integer default 0;
alter table public.profiles add column if not exists selected_categories_count integer default 0;
alter table public.profiles add column if not exists selected_domains_count integer default 0;
alter table public.profiles add column if not exists selected_categories text[] default '{}';
alter table public.profiles add column if not exists selected_apps text[] default '{}';
alter table public.profiles add column if not exists schedule_start text default '9:00 AM';
alter table public.profiles add column if not exists schedule_end text default '5:00 PM';
alter table public.profiles add column if not exists active_days text[] default array['M', 'T', 'W', 'T2', 'F'];
alter table public.profiles add column if not exists strict_lock boolean default true;

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile"
  on public.profiles for delete
  using (auth.uid() = id);

-- Allow an authenticated user to permanently delete their own account
create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_user_account() from public;
grant execute on function public.delete_user_account() to authenticated;

-- Trigger to automatically create a profile row on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ============================================================================
-- 2. FLEXIBLE FOCUS SCHEDULES TABLE (Multiple rules, days, times, & apps)
-- ============================================================================
create table if not exists public.focus_schedules (
  id text not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  start_time text not null,
  end_time text not null,
  active_days text[] not null default array['M', 'T', 'W', 'T2', 'F'],
  enforcement_mode text not null default 'Strict enforcement mode',
  is_active boolean not null default true,
  selected_app_ids text[] not null default '{}',
  extra_blocked_count integer not null default 0,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null,
  primary key (user_id, id)
);

-- Migrate legacy single-column primary key (`id`) to composite `(user_id, id)`.
do $$
declare
  pk_name text;
  pk_cols text[];
begin
  select c.conname, array_agg(a.attname::text order by k.ord)
    into pk_name, pk_cols
  from pg_constraint c
  join unnest(c.conkey) with ordinality as k(attnum, ord) on true
  join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
  where c.conrelid = 'public.focus_schedules'::regclass
    and c.contype = 'p'
  group by c.conname;

  if pk_name is not null and pk_cols <> array['user_id', 'id'] then
    execute format('alter table public.focus_schedules drop constraint %I', pk_name);
    alter table public.focus_schedules add primary key (user_id, id);
  elsif pk_name is null then
    alter table public.focus_schedules add primary key (user_id, id);
  end if;
end $$;

create index if not exists idx_focus_schedules_user_id
  on public.focus_schedules(user_id);

alter table public.focus_schedules enable row level security;

drop policy if exists "Users can view own focus schedules" on public.focus_schedules;
create policy "Users can view own focus schedules"
  on public.focus_schedules for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own focus schedules" on public.focus_schedules;
create policy "Users can insert own focus schedules"
  on public.focus_schedules for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own focus schedules" on public.focus_schedules;
create policy "Users can update own focus schedules"
  on public.focus_schedules for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own focus schedules" on public.focus_schedules;
create policy "Users can delete own focus schedules"
  on public.focus_schedules for delete
  using (auth.uid() = user_id);


-- ============================================================================
-- 3. DAILY FOCUS STATS TABLE (Tracks real daily focused time & pickups saved)
-- ============================================================================
create table if not exists public.daily_focus_stats (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  stat_date date not null default current_date,
  focused_minutes integer not null default 0,
  pickups_saved integer not null default 0,
  focus_score integer not null default 100,
  mindful_break_minutes integer not null default 0,
  updated_at timestamptz default timezone('utc'::text, now()) not null,
  unique (user_id, stat_date)
);

create index if not exists idx_daily_focus_stats_user_date
  on public.daily_focus_stats(user_id, stat_date);

alter table public.daily_focus_stats enable row level security;

drop policy if exists "Users can view own daily focus stats" on public.daily_focus_stats;
create policy "Users can view own daily focus stats"
  on public.daily_focus_stats for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own daily focus stats" on public.daily_focus_stats;
create policy "Users can insert own daily focus stats"
  on public.daily_focus_stats for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own daily focus stats" on public.daily_focus_stats;
create policy "Users can update own daily focus stats"
  on public.daily_focus_stats for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own daily focus stats" on public.daily_focus_stats;
create policy "Users can delete own daily focus stats"
  on public.daily_focus_stats for delete
  using (auth.uid() = user_id);


-- ============================================================================
-- 4. LOGIN ACTIVITY LOGS TABLE
-- ============================================================================
create table if not exists public.login_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  provider text,
  logged_in_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.login_logs enable row level security;

drop policy if exists "Users can view own login logs" on public.login_logs;
create policy "Users can view own login logs"
  on public.login_logs for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own login log" on public.login_logs;
create policy "Users can insert own login log"
  on public.login_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own login logs" on public.login_logs;
create policy "Users can delete own login logs"
  on public.login_logs for delete
  using (auth.uid() = user_id);


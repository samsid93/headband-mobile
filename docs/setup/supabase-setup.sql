-- ═══════════════════════════════════════════════════
-- HeadBand! — Supabase Setup
-- Run this entire file in: Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════

-- 1. PROFILES (extends auth.users — auto-created on signup)
create table if not exists public.profiles (
  id            uuid references auth.users(id) on delete cascade primary key,
  display_name  text not null default 'Player',
  avatar_url    text,
  created_at    timestamptz default now() not null,
  updated_at    timestamptz default now() not null
);

-- Auto-create profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1),
      'Player'
    ),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. GAME SESSIONS (one row per round played)
create table if not exists public.game_sessions (
  id            uuid default gen_random_uuid() primary key,
  user_id       uuid references public.profiles(id) on delete cascade not null,
  deck_id       text not null,
  deck_name     text not null,
  deck_icon     text not null default '',
  game_style    text not null check (game_style in ('headsup','charades')),
  game_mode     text not null check (game_mode in ('classic','team')),
  score         int  not null default 0,
  correct_count int  not null default 0,
  skip_count    int  not null default 0,
  timer_seconds int  not null default 60,
  played_at     timestamptz default now() not null
);

-- 3. BEST SCORES (per user per deck — upserted after every round)
create table if not exists public.best_scores (
  user_id       uuid references public.profiles(id) on delete cascade not null,
  deck_id       text not null,
  deck_name     text not null,
  deck_icon     text not null default '',
  best_score    int  not null default 0,
  total_rounds  int  not null default 0,
  total_correct int  not null default 0,
  total_skipped int  not null default 0,
  updated_at    timestamptz default now() not null,
  primary key (user_id, deck_id)
);

-- 4. ROW LEVEL SECURITY
alter table public.profiles      enable row level security;
alter table public.game_sessions enable row level security;
alter table public.best_scores   enable row level security;

-- Profiles: anyone can read, only owner can update
drop policy if exists "profiles_read_all"   on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_read_all"   on public.profiles for select using (true);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

-- Game sessions: owner inserts + reads only
drop policy if exists "sessions_insert_own" on public.game_sessions;
drop policy if exists "sessions_read_own"   on public.game_sessions;
create policy "sessions_insert_own" on public.game_sessions for insert with check (auth.uid() = user_id);
create policy "sessions_read_own"   on public.game_sessions for select  using (auth.uid() = user_id);

-- Best scores: owner upserts, everyone reads (leaderboard)
drop policy if exists "best_scores_insert_own" on public.best_scores;
drop policy if exists "best_scores_update_own" on public.best_scores;
drop policy if exists "best_scores_read_all"   on public.best_scores;
create policy "best_scores_insert_own"  on public.best_scores for insert with check (auth.uid() = user_id);
create policy "best_scores_update_own"  on public.best_scores for update using (auth.uid() = user_id);
create policy "best_scores_read_all"    on public.best_scores for select using (true);

-- 5. GLOBAL LEADERBOARD VIEW
create or replace view public.global_leaderboard as
select
  bs.user_id,
  p.display_name,
  p.avatar_url,
  bs.deck_id,
  bs.deck_name,
  bs.deck_icon,
  bs.best_score,
  bs.total_rounds,
  bs.total_correct,
  bs.total_skipped,
  bs.updated_at
from public.best_scores bs
join public.profiles p on p.id = bs.user_id
order by bs.best_score desc;

-- 6. SUBSCRIPTION COLUMNS ON PROFILES
alter table public.profiles
  add column if not exists sub_type       text not null default 'free',
  add column if not exists sub_expires_at timestamptz,
  add column if not exists sub_platform   text,
  add column if not exists sub_product_id text;

-- Index for quick expiry checks
create index if not exists profiles_sub_expires_idx on public.profiles (sub_expires_at);

-- 7. ADMIN READ POLICIES (allow admin email to read all data)
-- Run after Step 4 — required for admin dashboard to work

drop policy if exists "admin_read_sessions" on public.game_sessions;
create policy "admin_read_sessions" on public.game_sessions
  for select using (
    auth.uid() = user_id
    or (select auth.jwt()->>'email') = 'usamasiddiqui93@gmail.com'
  );

drop policy if exists "admin_read_best_scores" on public.best_scores;
create policy "admin_read_best_scores" on public.best_scores
  for select using (
    auth.uid() = user_id
    or (select auth.jwt()->>'email') = 'usamasiddiqui93@gmail.com'
  );

-- Done! Go to Supabase → Authentication → Providers → enable Email and Google

create extension if not exists pgcrypto;

create table if not exists public.user_plants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  common_name text not null default '',
  aliases_json text not null default '[]',
  english_name text not null default '',
  scientific_name text not null,
  family text not null default '',
  description text not null default '',
  habitat text not null default '',
  light_requirement text not null default '',
  watering_needs text not null default '',
  care_level text not null default '',
  suitable_temperature text not null default '',
  soil_type text not null default '',
  fertilizing_tips text not null default '',
  toxicity_warning text not null default '',
  uses_json text not null default '[]',
  maximum_size text not null default '',
  feng_shui_meaning text not null default '',
  origin text not null default '',
  common_issues text not null default '',
  image_path text not null default '',
  is_favorite boolean not null default false,
  is_offline_available boolean not null default true,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, scientific_name)
);

create table if not exists public.user_recognition_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plant_remote_id uuid references public.user_plants (id) on delete set null,
  plant_scientific_name text not null,
  image_path text not null default '',
  confidence double precision not null default 0,
  captured_at timestamptz not null,
  raw_json text not null default '{}',
  client_record_key text not null,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, client_record_key)
);

create table if not exists public.user_recognition_daily_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  usage_date date not null,
  request_count integer not null default 0,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, usage_date)
);

alter table public.user_plants enable row level security;
alter table public.user_recognition_records enable row level security;
alter table public.user_recognition_daily_usage enable row level security;

drop policy if exists "users_manage_own_plants" on public.user_plants;
create policy "users_manage_own_plants"
on public.user_plants
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users_manage_own_records" on public.user_recognition_records;
create policy "users_manage_own_records"
on public.user_recognition_records
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users_read_own_daily_usage" on public.user_recognition_daily_usage;
create policy "users_read_own_daily_usage"
on public.user_recognition_daily_usage
for select
using (auth.uid() = user_id);

create or replace function public.consume_recognition_daily_quota(
  p_user_id uuid,
  p_daily_limit integer default 15
)
returns table (
  allowed boolean,
  used_count integer,
  remaining_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := timezone('Asia/Bangkok', now())::date;
  v_current_count integer;
begin
  if auth.uid() is distinct from p_user_id then
    raise exception 'not authorized';
  end if;

  insert into public.user_recognition_daily_usage (
    user_id,
    usage_date,
    request_count
  )
  values (p_user_id, v_today, 0)
  on conflict (user_id, usage_date) do nothing;

  select request_count
  into v_current_count
  from public.user_recognition_daily_usage
  where user_id = p_user_id
    and usage_date = v_today
  for update;

  if coalesce(v_current_count, 0) >= p_daily_limit then
    return query
    select
      false,
      coalesce(v_current_count, 0),
      greatest(p_daily_limit - coalesce(v_current_count, 0), 0);
    return;
  end if;

  update public.user_recognition_daily_usage
  set
    request_count = coalesce(v_current_count, 0) + 1,
    updated_at = now()
  where user_id = p_user_id
    and usage_date = v_today;

  return query
  select
    true,
    coalesce(v_current_count, 0) + 1,
    greatest(p_daily_limit - (coalesce(v_current_count, 0) + 1), 0);
end;
$$;

revoke all on function public.consume_recognition_daily_quota(uuid, integer) from public;
grant execute on function public.consume_recognition_daily_quota(uuid, integer) to authenticated;

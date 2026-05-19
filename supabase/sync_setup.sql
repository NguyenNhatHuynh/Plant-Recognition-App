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

alter table public.user_plants enable row level security;
alter table public.user_recognition_records enable row level security;

create policy "users_manage_own_plants"
on public.user_plants
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users_manage_own_records"
on public.user_recognition_records
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

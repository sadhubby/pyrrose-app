-- Pyrrose initial schema
-- Apply via: Supabase Dashboard → SQL Editor → paste, or `supabase db push`.
-- RLS: the viewer reads bouquets with the anon key; the app inserts new ones.
-- No auth in MVP — policies are deliberately permissive for anon; tighten in Phase 6.

create table if not exists public.bouquets (
  id uuid primary key default gen_random_uuid(),
  share_slug text not null unique,
  title text not null default '',
  -- Array of placements: [{ flowerId, slot, height, tilt, scale }]
  -- One jsonb column keeps the MVP simple; normalize when media arrives.
  arrangement jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists bouquets_share_slug_idx on public.bouquets (share_slug);

alter table public.bouquets enable row level security;

create policy "Anyone can read bouquets"
  on public.bouquets for select
  to anon
  using (true);

create policy "Anyone can create bouquets"
  on public.bouquets for insert
  to anon
  with check (true);

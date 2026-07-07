-- ============================================================
-- OFF-LIMITS ENTERTAINMENT — Supabase (Postgres) Schema
-- Run this once in the Supabase SQL Editor (Project → SQL Editor → New query)
-- ============================================================

-- ---- Artists ----
create table if not exists artists (
    id          bigint generated always as identity primary key,
    slug        text not null unique,
    name        text not null,
    genre       text not null,
    bio         text,
    photo_url   text,
    spotify_url text,
    apple_url   text,
    instagram   text,
    youtube     text,
    is_active   boolean not null default true,
    created_at  timestamptz not null default now()
);

-- ---- Releases ----
create table if not exists releases (
    id           bigint generated always as identity primary key,
    artist_id    bigint not null references artists(id) on delete cascade,
    title        text not null,
    type         text not null default 'single' check (type in ('single','ep','album','mixtape')),
    cover_url    text,
    spotify_url  text,
    apple_url    text,
    youtube_url  text,
    release_date date not null,
    is_featured  boolean not null default false,
    created_at   timestamptz not null default now()
);

-- ---- Events ----
create table if not exists events (
    id          bigint generated always as identity primary key,
    title       text not null,
    artist_id   bigint references artists(id) on delete set null,
    venue       text not null,
    city        text not null,
    country     text not null,
    event_date  date not null,
    ticket_url  text,
    is_sold_out boolean not null default false,
    created_at  timestamptz not null default now()
);

-- ---- Contact Messages ----
create table if not exists contact_messages (
    id         bigint generated always as identity primary key,
    name       text not null,
    email      text not null,
    subject    text not null,
    message    text not null,
    is_read    boolean not null default false,
    created_at timestamptz not null default now()
);

-- ---- Demo Submissions ----
create table if not exists demo_submissions (
    id             bigint generated always as identity primary key,
    artist_name    text not null,
    real_name      text not null,
    email          text not null,
    phone          text,
    genre          text not null,
    country        text not null,
    stream_link    text not null,
    bio            text,
    demo_file_path text,
    terms_accepted boolean not null default false,
    status         text not null default 'pending' check (status in ('pending','reviewing','accepted','rejected')),
    ar_notes       text,
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

-- ---- Newsletter Subscribers ----
create table if not exists newsletter_subscribers (
    id              bigint generated always as identity primary key,
    email           text not null unique,
    is_active       boolean not null default true,
    subscribed_at   timestamptz not null default now(),
    unsubscribed_at timestamptz
);

-- ---- Portal Profiles (one row per authenticated artist, linked to Supabase Auth) ----
create table if not exists portal_profiles (
    id         uuid primary key references auth.users(id) on delete cascade,
    artist_id  bigint not null references artists(id) on delete cascade,
    username   text not null unique,
    last_login timestamptz,
    created_at timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table artists                enable row level security;
alter table releases               enable row level security;
alter table events                  enable row level security;
alter table contact_messages       enable row level security;
alter table demo_submissions       enable row level security;
alter table newsletter_subscribers enable row level security;
alter table portal_profiles        enable row level security;

-- Public (anon) can read active artists / releases / events — powers the website
create policy "Public can read active artists" on artists
    for select using (is_active = true);

create policy "Public can read releases" on releases
    for select using (true);

create policy "Public can read events" on events
    for select using (true);

-- Public (anon) can INSERT into the public forms, but never read them back
create policy "Anyone can submit a contact message" on contact_messages
    for insert with check (true);

create policy "Anyone can submit a demo" on demo_submissions
    for insert with check (true);

create policy "Anyone can subscribe to the newsletter" on newsletter_subscribers
    for insert with check (true);

-- Logged-in artists can see/update their own portal profile
create policy "Artists can read their own profile" on portal_profiles
    for select using (auth.uid() = id);

create policy "Artists can update their own profile" on portal_profiles
    for update using (auth.uid() = id);

-- Logged-in artists can read demo submissions (A&R review queue) and their
-- own releases/events, and manage their own artist row
create policy "Logged-in artists can read demo submissions" on demo_submissions
    for select using (auth.role() = 'authenticated');

create policy "Artists can read their own artist row" on artists
    for select using (
        auth.role() = 'authenticated'
        and id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid())
    );

create policy "Artists can update their own artist row" on artists
    for update using (
        auth.role() = 'authenticated'
        and id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid())
    );

-- ============================================================
-- STORAGE — bucket for demo audio uploads
-- ============================================================
insert into storage.buckets (id, name, public)
values ('demos', 'demos', false)
on conflict (id) do nothing;

create policy "Anyone can upload a demo file" on storage.objects
    for insert with check (bucket_id = 'demos');

create policy "Authenticated artists can read demo files" on storage.objects
    for select using (bucket_id = 'demos' and auth.role() = 'authenticated');

-- ============================================================
-- SEED DATA — Abuja, Nigeria based (matches the original roster)
-- ============================================================
insert into artists (slug, name, genre, bio, is_active) values
('vandal-x',     'Vandal X',     'Hip-Hop / Alternative', 'Abuja-born rapper and producer blending alternative hip-hop with raw street narratives. Vandal X is the voice of a generation that refuses to be silenced.', true),
('luna-eclipse', 'Luna Eclipse', 'Electronic Pop',         'Electronic pop artist from Abuja crafting hypnotic soundscapes that bridge Afro-fusion and global electronic music.', true),
('aria-vance',   'Aria Vance',   'R&B / Soul',             'Soulful R&B vocalist from the FCT with a voice that cuts through noise. Aria Vance writes music that heals.', true),
('kxng-dayo',    'Kxng Dayo',    'Afrobeats / Dancehall',  'Afrobeats heavyweight from Abuja taking Nigerian sound to the world stage. Kxng Dayo fuses Afrobeats, Dancehall, and Afropop.', true),
('phantom',      'Phantom',      'Trap / Dark Hip-Hop',    'Dark trap artist from the streets of Abuja. Phantom''s music is cinematic, intense, and unapologetically raw.', true),
('zara-nox',     'Zara Nox',     'Neo-Soul / R&B',         'Neo-soul singer-songwriter based in Abuja. Zara Nox blends jazz-influenced production with deeply personal lyricism.', true),
('neon-drift',   'Neon Drift',   'Electronic / Synthwave', 'Abuja-based electronic producer pushing the boundaries of synthwave and Afro-electronic fusion.', true),
('soleil',       'Soleil',       'Afropop / World',        'Afropop artist and performer from Abuja with a global vision. Soleil''s music celebrates African identity on the world stage.', true)
on conflict (slug) do nothing;

insert into releases (artist_id, title, type, release_date, is_featured)
select a.id, r.title, r.type, r.release_date::date, r.is_featured
from (values
    ('vandal-x',     'Signal Lost',        'album',   '2026-05-01', true),
    ('aria-vance',   'Midnight Frequency', 'single',  '2026-04-15', false),
    ('luna-eclipse', 'Neon Pulse EP',      'ep',      '2026-03-20', false),
    ('kxng-dayo',    'Lagos to London',    'album',   '2026-02-10', false),
    ('phantom',      'Dark Matter',        'mixtape', '2026-01-28', false)
) as r(slug, title, type, release_date, is_featured)
join artists a on a.slug = r.slug
on conflict do nothing;

insert into events (title, artist_id, venue, city, country, event_date, is_sold_out)
select e.title, a.id, e.venue, e.city, e.country, e.event_date::date, e.is_sold_out
from (values
    ('Off-Limits Fest 2026',           null,            'International Conference Centre', 'Abuja',    'Nigeria', '2026-06-14', false),
    ('Luna Eclipse — Neon Pulse Tour', 'luna-eclipse',  'O2 Academy Brixton',              'London',   'UK',      '2026-07-22', false),
    ('Aria Vance — Midnight Sessions', 'aria-vance',    'Brooklyn Steel',                  'New York', 'USA',     '2026-08-09', false),
    ('Phantom — Dark Matter Live',     'phantom',       'Rebel Entertainment Complex',     'Toronto',  'Canada',  '2026-09-30', true),
    ('Kxng Dayo — Abuja Homecoming',   'kxng-dayo',     'Transcorp Hilton Abuja',          'Abuja',    'Nigeria', '2026-10-18', false)
) as e(title, slug, venue, city, country, event_date, is_sold_out)
left join artists a on a.slug = e.slug
on conflict do nothing;

-- ============================================================
-- Artist portal login — after running this schema, create the admin's
-- Auth user from the Supabase Dashboard (Authentication → Users → Add user,
-- email + password), then link it to an artist by running:
--
--   insert into portal_profiles (id, artist_id, username)
--   values ('<the new user''s UUID from the dashboard>',
--           (select id from artists where slug = 'vandal-x'),
--           'admin');
-- ============================================================

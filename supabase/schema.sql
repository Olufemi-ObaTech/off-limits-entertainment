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
    demo_file_paths text[] not null default '{}',
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

-- ---- Portal Profiles (one row per staff/artist portal account, linked to Supabase Auth)
-- role='admin'   -> label staff, sees everything
-- role='manager' -> manages one or more artists via manager_artists
-- role='artist'  -> the artist themself; artist_id identifies which artist row is theirs
create table if not exists portal_profiles (
    id                uuid primary key references auth.users(id) on delete cascade,
    role              text not null default 'artist' check (role in ('admin','manager','artist')),
    artist_id         bigint references artists(id) on delete cascade,
    username          text not null unique,
    messaging_enabled boolean not null default true,
    last_login timestamptz,
    created_at timestamptz not null default now()
);

-- ---- Manager <-> Artist assignments (many-to-many: a manager can manage several artists) ----
create table if not exists manager_artists (
    manager_id uuid not null references portal_profiles(id) on delete cascade,
    artist_id  bigint not null references artists(id) on delete cascade,
    primary key (manager_id, artist_id)
);

-- ---- Artist Media Library (audio/video uploads artists can store, play, and share) ----
create table if not exists artist_media (
    id          bigint generated always as identity primary key,
    artist_id   bigint not null references artists(id) on delete cascade,
    uploaded_by uuid not null references portal_profiles(id) on delete cascade,
    title       text not null,
    media_type  text not null check (media_type in ('audio','video')),
    file_path   text not null,
    is_public   boolean not null default true,
    created_at  timestamptz not null default now()
);

-- ---- Team Messages (Admin <-> Manager <-> Artist internal chat) ----
create table if not exists team_messages (
    id          bigint generated always as identity primary key,
    sender_id   uuid not null references portal_profiles(id) on delete cascade,
    recipient_id uuid not null references portal_profiles(id) on delete cascade,
    message     text not null,
    is_read     boolean not null default false,
    created_at  timestamptz not null default now()
);

-- ---- Fan / User Accounts (public sign-up, separate from the staff/artist portal) ----
create table if not exists fan_profiles (
    id                uuid primary key references auth.users(id) on delete cascade,
    display_name      text not null,
    messaging_enabled boolean not null default true,
    created_at        timestamptz not null default now()
);

-- ---- Direct Messages (two-way chat between a fan and Off-Limits staff) ----
create table if not exists direct_messages (
    id         bigint generated always as identity primary key,
    user_id    uuid not null references fan_profiles(id) on delete cascade,
    sender     text not null check (sender in ('user','admin')),
    message    text not null,
    is_read    boolean not null default false,
    created_at timestamptz not null default now()
);

-- ============================================================
-- HELPERS — security definer so they can check portal_profiles
-- without triggering recursive RLS lookups
-- ============================================================
create or replace function is_portal_staff()
returns boolean
language sql
security definer
set search_path = public
as $$
    select exists (select 1 from portal_profiles where portal_profiles.id = auth.uid());
$$;

create or replace function is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
    select exists (select 1 from portal_profiles where portal_profiles.id = auth.uid() and role = 'admin');
$$;

create or replace function manages_artist(target_artist_id bigint)
returns boolean
language sql
security definer
set search_path = public
as $$
    select exists (
        select 1 from manager_artists
        where manager_id = auth.uid() and artist_id = target_artist_id
    );
$$;

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
alter table manager_artists        enable row level security;
alter table artist_media           enable row level security;
alter table team_messages          enable row level security;
alter table fan_profiles           enable row level security;
alter table direct_messages        enable row level security;

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

-- Any staff member can see the basic team directory (name/role) so
-- admin/manager/artist can find each other to start a Team Chat
create policy "Staff can read the team directory" on portal_profiles
    for select using (is_portal_staff());

-- Staff can update their own profile, but NOT their own messaging_enabled flag
-- (only an admin can mute/unmute a staff member's messaging)
create policy "Staff can update their own profile" on portal_profiles
    for update using (auth.uid() = id)
    with check (
        auth.uid() = id
        and messaging_enabled = (select p.messaging_enabled from portal_profiles p where p.id = auth.uid())
    );

create policy "Admins can update any portal profile" on portal_profiles
    for update using (is_admin());

-- Only Admin staff review the A&R demo queue (managers/artists don't need it)
create policy "Admins can read demo submissions" on demo_submissions
    for select using (is_admin());

create policy "Admins can read contact messages" on contact_messages
    for select using (is_admin());

create policy "Admins can read newsletter subscribers" on newsletter_subscribers
    for select using (is_admin());

-- Artists/managers can read the artist row(s) relevant to them; admins read all
create policy "Portal roles can read relevant artists" on artists
    for select using (
        is_admin()
        or id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid() and role = 'artist')
        or id in (select artist_id from manager_artists where manager_id = auth.uid())
    );

create policy "Admins can update any artist" on artists
    for update using (is_admin());

create policy "Artists can update their own artist row" on artists
    for update using (
        id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid() and role = 'artist')
    );

-- Managers can create/update events & release dates for the artists they manage
create policy "Admins can write events" on events
    for all using (is_admin()) with check (is_admin());

create policy "Managers can write events for their artists" on events
    for all using (manages_artist(artist_id)) with check (manages_artist(artist_id));

create policy "Admins can write releases" on releases
    for all using (is_admin()) with check (is_admin());

create policy "Managers can write releases for their artists" on releases
    for all using (manages_artist(artist_id)) with check (manages_artist(artist_id));

-- manager_artists: staff can see assignments relevant to them; only admins manage them
create policy "Admins manage manager_artists" on manager_artists
    for all using (is_admin()) with check (is_admin());

create policy "Managers can read their own assignments" on manager_artists
    for select using (auth.uid() = manager_id);

create policy "Artists can read who manages them" on manager_artists
    for select using (
        artist_id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid() and role = 'artist')
    );

-- artist_media: artists manage their own uploads; admins/managers of that artist can view; public can view public media
create policy "Artists manage their own media" on artist_media
    for all using (
        artist_id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid() and role = 'artist')
    ) with check (
        artist_id in (select artist_id from portal_profiles where portal_profiles.id = auth.uid() and role = 'artist')
    );

create policy "Admins can read all media" on artist_media
    for select using (is_admin());

create policy "Managers can read their artists' media" on artist_media
    for select using (manages_artist(artist_id));

create policy "Public can read public media" on artist_media
    for select using (is_public = true);

-- team_messages: any portal user can read/send messages in threads they're part of
create policy "Staff can read their own conversations" on team_messages
    for select using (auth.uid() = sender_id or auth.uid() = recipient_id);

create policy "Staff can send messages" on team_messages
    for insert with check (
        auth.uid() = sender_id
        and exists (select 1 from portal_profiles where id = auth.uid() and messaging_enabled = true)
    );

-- Fans manage their own profile; sign-up creates this row client-side
create policy "Fans can read their own profile" on fan_profiles
    for select using (auth.uid() = id);

create policy "Fans can create their own profile" on fan_profiles
    for insert with check (auth.uid() = id);

-- Fans can update their own profile, but NOT their own messaging_enabled flag
-- (only an admin can mute/unmute a fan's messaging)
create policy "Fans can update their own profile" on fan_profiles
    for update using (auth.uid() = id)
    with check (
        auth.uid() = id
        and messaging_enabled = (select f.messaging_enabled from fan_profiles f where f.id = auth.uid())
    );

create policy "Admins can update any fan profile" on fan_profiles
    for update using (is_admin());

-- Only admins manage the fan support inbox (not managers/artists)
create policy "Admins can read all fan profiles" on fan_profiles
    for select using (is_admin());

-- Direct messages: a fan sees/sends only their own thread; staff see/send all
create policy "Fans can read their own messages" on direct_messages
    for select using (auth.uid() = user_id);

create policy "Fans can send messages in their own thread" on direct_messages
    for insert with check (
        auth.uid() = user_id and sender = 'user'
        and exists (select 1 from fan_profiles where id = auth.uid() and messaging_enabled = true)
    );

create policy "Admins can read all conversations" on direct_messages
    for select using (is_admin());

create policy "Admins can reply in any conversation" on direct_messages
    for insert with check (
        is_admin() and sender = 'admin'
        and exists (select 1 from portal_profiles where id = auth.uid() and messaging_enabled = true)
    );

-- ============================================================
-- STORAGE — buckets for demo uploads and the artist media library
-- ============================================================
insert into storage.buckets (id, name, public)
values ('demos', 'demos', false)
on conflict (id) do nothing;

create policy "Anyone can upload a demo file" on storage.objects
    for insert with check (bucket_id = 'demos');

create policy "Admins can read demo files" on storage.objects
    for select using (bucket_id = 'demos' and is_admin());

-- Public bucket so artists can share a direct link to their uploaded audio/video
insert into storage.buckets (id, name, public)
values ('artist-media', 'artist-media', true)
on conflict (id) do nothing;

create policy "Artists can upload their own media" on storage.objects
    for insert with check (bucket_id = 'artist-media' and is_portal_staff());

create policy "Artists can delete their own media" on storage.objects
    for delete using (bucket_id = 'artist-media' and owner = auth.uid());

create policy "Anyone can view artist media files" on storage.objects
    for select using (bucket_id = 'artist-media');

-- ============================================================
-- TRIGGER — auto-send a welcome message to every new fan account
-- ============================================================
create or replace function send_fan_welcome_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into direct_messages (user_id, sender, message)
    values (
        new.id,
        'admin',
        'Welcome to Off-Limits Entertainment, ' || new.display_name || '! Browse the latest releases and media, check upcoming events, and message us here anytime — we typically reply within 1-2 business days.'
    );
    return new;
end;
$$;

drop trigger if exists trg_fan_welcome_message on fan_profiles;
create trigger trg_fan_welcome_message
    after insert on fan_profiles
    for each row execute function send_fan_welcome_message();

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
-- PROVISIONING ACCOUNTS — after running this schema, create each Auth user
-- from Supabase Dashboard → Authentication → Users → Add user (tick "Auto
-- Confirm User" so it can log in immediately), then link it with the SQL
-- below using the UUID shown for that user.
--
-- 1) ADMIN (label staff) — sees everything, reviews demos, assigns managers
--   insert into portal_profiles (id, role, username)
--   values ('<UUID of admin@offlimitsentertainment.com>', 'admin', 'admin');
--
-- 2) ARTIST MANAGER — manages one or more artists' events & release dates
--   insert into portal_profiles (id, role, username)
--   values ('<UUID of manager@offlimitsentertainment.com>', 'manager', 'manager');
--
--   insert into manager_artists (manager_id, artist_id)
--   values ('<same manager UUID>', (select id from artists where slug = 'vandal-x'));
--
-- 3) ARTIST — the demo artist login, tied to the Vandal X artist row
--   insert into portal_profiles (id, role, artist_id, username)
--   values ('<UUID of artist@offlimitsentertainment.com>', 'artist',
--           (select id from artists where slug = 'vandal-x'), 'vandalx');
--
-- 4) DEMO FAN (public account.html login)
--   insert into fan_profiles (id, display_name)
--   values ('<UUID of demo@offlimitsentertainment.com>', 'Demo Fan');
-- ============================================================

/**
 * Static fallback roster — used on roster.html / artist.html whenever
 * Supabase isn't configured yet, or a query fails, so the pages never
 * render empty before the database is wired up.
 */
window.ARTISTS_FALLBACK = [
    { slug: 'vandal-x',     name: 'Vandal X',     genre: 'Hip-Hop / Alternative', photo_url: 'assets/images/img3.jpg', bio: "Abuja-born rapper and producer blending alternative hip-hop with raw street narratives. Vandal X is the voice of a generation that refuses to be silenced." },
    { slug: 'luna-eclipse', name: 'Luna Eclipse', genre: 'Electronic Pop',        photo_url: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=600', bio: 'Electronic pop artist from Abuja crafting hypnotic soundscapes that bridge Afro-fusion and global electronic music.' },
    { slug: 'aria-vance',   name: 'Aria Vance',   genre: 'R&B / Soul',            photo_url: 'assets/images/photo_2_2026-05-16_07-20-49.jpg', bio: 'Soulful R&B vocalist from the FCT with a voice that cuts through noise. Aria Vance writes music that heals.' },
    { slug: 'kxng-dayo',    name: 'Kxng Dayo',    genre: 'Afrobeats / Dancehall', photo_url: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?q=80&w=600', bio: 'Afrobeats heavyweight from Abuja taking Nigerian sound to the world stage. Kxng Dayo fuses Afrobeats, Dancehall, and Afropop.' },
    { slug: 'phantom',      name: 'Phantom',      genre: 'Trap / Dark Hip-Hop',   photo_url: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=600', bio: "Dark trap artist from the streets of Abuja. Phantom's music is cinematic, intense, and unapologetically raw." },
    { slug: 'zara-nox',     name: 'Zara Nox',     genre: 'Neo-Soul / R&B',        photo_url: 'assets/images/img5.jpg', bio: 'Neo-soul singer-songwriter based in Abuja. Zara Nox blends jazz-influenced production with deeply personal lyricism.' },
    { slug: 'neon-drift',   name: 'Neon Drift',   genre: 'Electronic / Synthwave',photo_url: 'assets/images/img2.jpg', bio: 'Abuja-based electronic producer pushing the boundaries of synthwave and Afro-electronic fusion.' },
    { slug: 'soleil',       name: 'Soleil',       genre: 'Afropop / World',       photo_url: 'assets/images/img1.jpg', bio: "Afropop artist and performer from Abuja with a global vision. Soleil's music celebrates African identity on the world stage." },
];

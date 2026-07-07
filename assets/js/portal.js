/**
 * OFF-LIMITS ENTERTAINMENT — Artist/Staff Portal shared logic
 * Requires supabase-config.js + supabase-client.js loaded first.
 */
'use strict';

/**
 * Guards a portal page: redirects to login if there's no active Supabase
 * session, otherwise resolves the signed-in staff member's profile, role,
 * and (for managers) the list of artist IDs they manage.
 * Returns { user, profile, role, artist, managedArtistIds } or redirects.
 */
async function requirePortalAuth() {
    if (!supabaseClient) {
        document.body.innerHTML = '<p style="color:#ef4444;font-family:monospace;padding:2rem;">Supabase is not configured. Edit assets/js/supabase-config.js with your project URL and anon key.</p>';
        return new Promise(() => {});
    }

    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) {
        window.location.href = 'login.html';
        return new Promise(() => {});
    }

    const { data: profile, error: profileError } = await supabaseClient
        .from('portal_profiles')
        .select('*, artists(*)')
        .eq('id', session.user.id)
        .single();

    if (profileError || !profile) {
        window.location.href = 'login.html';
        return new Promise(() => {});
    }

    let managedArtistIds = [];
    if (profile.role === 'manager') {
        const { data: assignments } = await supabaseClient
            .from('manager_artists').select('artist_id').eq('manager_id', session.user.id);
        managedArtistIds = (assignments || []).map(a => a.artist_id);
    }

    document.querySelectorAll('[data-artist-name]').forEach(el => {
        el.textContent = profile.artists?.name || profile.username;
    });
    document.querySelectorAll('[data-current-date]').forEach(el => {
        el.textContent = new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    });
    document.querySelectorAll('[data-role-badge]').forEach(el => {
        el.textContent = profile.role.charAt(0).toUpperCase() + profile.role.slice(1);
    });

    // Show/hide sidebar links and page sections based on role.
    // Add data-roles="admin,manager" to any element that should only show for those roles.
    document.querySelectorAll('[data-roles]').forEach(el => {
        const allowed = el.getAttribute('data-roles').split(',').map(r => r.trim());
        if (!allowed.includes(profile.role)) el.remove();
    });

    return { user: session.user, profile, role: profile.role, artist: profile.artists, managedArtistIds };
}

function initPortalChrome() {
    const logoutLink = document.getElementById('portalLogout');
    if (logoutLink) {
        logoutLink.addEventListener('click', async (e) => {
            e.preventDefault();
            if (supabaseClient) await supabaseClient.auth.signOut();
            window.location.href = 'login.html';
        });
    }

    const toggleBtn = document.getElementById('sidebarToggle');
    const sidebar = document.getElementById('sidebar');
    if (toggleBtn && sidebar) {
        toggleBtn.addEventListener('click', () => sidebar.classList.toggle('open'));
    }
}

document.addEventListener('DOMContentLoaded', initPortalChrome);

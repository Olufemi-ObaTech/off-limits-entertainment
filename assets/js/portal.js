/**
 * OFF-LIMITS ENTERTAINMENT — Artist Portal shared logic
 * Requires supabase-config.js + supabase-client.js loaded first.
 */
'use strict';

/**
 * Guards a portal page: redirects to login if there's no active Supabase
 * session, otherwise resolves the signed-in user's artist profile.
 * Returns { user, profile, artist } or redirects and never resolves.
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

    document.querySelectorAll('[data-artist-name]').forEach(el => {
        el.textContent = profile.artists?.name || profile.username;
    });
    document.querySelectorAll('[data-current-date]').forEach(el => {
        el.textContent = new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    });

    return { user: session.user, profile, artist: profile.artists };
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

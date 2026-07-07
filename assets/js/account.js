/**
 * OFF-LIMITS ENTERTAINMENT — Fan account shared logic
 * Requires supabase-config.js + supabase-client.js loaded first.
 */
'use strict';

async function requireFanAuth() {
    if (!supabaseClient) {
        document.body.innerHTML = '<p style="color:#ef4444;font-family:monospace;padding:2rem;">Supabase is not configured. Edit assets/js/supabase-config.js.</p>';
        return new Promise(() => {});
    }

    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) {
        window.location.href = 'login.html';
        return new Promise(() => {});
    }

    let { data: profile } = await supabaseClient
        .from('fan_profiles').select('*').eq('id', session.user.id).single();

    if (!profile) {
        const { data: created } = await supabaseClient
            .from('fan_profiles')
            .insert({ id: session.user.id, display_name: session.user.email.split('@')[0] })
            .select().single();
        profile = created;
    }

    return { user: session.user, profile };
}

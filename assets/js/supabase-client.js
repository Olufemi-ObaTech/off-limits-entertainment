/**
 * OFF-LIMITS ENTERTAINMENT — Shared Supabase client
 * Requires supabase-config.js and the Supabase JS CDN script to load first.
 */
'use strict';

const supabaseClient = (window.SUPABASE_URL && window.SUPABASE_URL !== 'YOUR_SUPABASE_PROJECT_URL')
    ? window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_ANON_KEY)
    : null;

if (!supabaseClient) {
    console.warn('Supabase is not configured yet — edit assets/js/supabase-config.js with your project URL and anon key.');
}

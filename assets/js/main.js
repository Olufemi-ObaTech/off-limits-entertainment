/**
 * OFF-LIMITS ENTERTAINMENT — MAIN JAVASCRIPT
 * Handles: Preloader, Custom Cursor, Navbar, Counters,
 *          Artist Filter, Video Modal, Music Player,
 *          Form Submissions (AJAX), AOS, Back-to-Top
 */

'use strict';

/* ============================================================
   1. PRELOADER
   ============================================================ */
window.addEventListener('load', () => {
    const preloader = document.getElementById('preloader');
    if (!preloader) return;
    setTimeout(() => {
        preloader.classList.add('hidden');
        // Init AOS after preloader
        AOS.init({ duration: 700, once: true, offset: 60, easing: 'ease-out-cubic' });
        // Start counters
        initCounters();
    }, 1900);
});

/* ============================================================
   2. CUSTOM CURSOR (desktop/mouse only — skipped on touch devices)
   ============================================================ */
const cursorDot     = document.getElementById('cursorDot');
const cursorOutline = document.getElementById('cursorOutline');
const isTouchDevice  = window.matchMedia('(hover: none), (pointer: coarse)').matches;

if (cursorDot && cursorOutline && !isTouchDevice) {
    let mouseX = 0, mouseY = 0;
    let outlineX = 0, outlineY = 0;

    document.addEventListener('mousemove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
        cursorDot.style.left = mouseX + 'px';
        cursorDot.style.top  = mouseY + 'px';
    });

    // Smooth outline follow
    function animateCursor() {
        outlineX += (mouseX - outlineX) * 0.12;
        outlineY += (mouseY - outlineY) * 0.12;
        cursorOutline.style.left = outlineX + 'px';
        cursorOutline.style.top  = outlineY + 'px';
        requestAnimationFrame(animateCursor);
    }
    animateCursor();

    // Hover effect on interactive elements
    const hoverTargets = document.querySelectorAll('a, button, .artist-card, .release-card, .merch-card, .video-card, .filter-btn');
    hoverTargets.forEach(el => {
        el.addEventListener('mouseenter', () => cursorOutline.classList.add('hovered'));
        el.addEventListener('mouseleave', () => cursorOutline.classList.remove('hovered'));
    });

    // Hide cursor when leaving window
    document.addEventListener('mouseleave', () => {
        cursorDot.style.opacity = '0';
        cursorOutline.style.opacity = '0';
    });
    document.addEventListener('mouseenter', () => {
        cursorDot.style.opacity = '1';
        cursorOutline.style.opacity = '0.6';
    });
}

/* ============================================================
   3. NAVBAR — Scroll Behavior (rAF-throttled, single scroll listener
      shared with active-nav-link + parallax for smooth mobile scrolling)
   ============================================================ */
const navbar = document.getElementById('mainNavbar');
const sections = document.querySelectorAll('section[id], header[id]');
const navLinks  = document.querySelectorAll('.nav-hover');
const backToTopBtn = document.getElementById('backToTop');
const heroVideoEl = document.getElementById('heroVideo');

let scrollTicking = false;
function onScrollFrame() {
    const scrollY = window.scrollY;

    if (navbar) {
        navbar.classList.toggle('scrolled', scrollY > 60);
    }

    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop - 100;
        if (scrollY >= sectionTop) current = section.getAttribute('id');
    });
    navLinks.forEach(link => {
        link.classList.toggle('active', link.getAttribute('href') === '#' + current);
    });

    if (backToTopBtn) backToTopBtn.classList.toggle('visible', scrollY > 400);

    if (heroVideoEl && scrollY < window.innerHeight) {
        heroVideoEl.style.transform = `translateY(${scrollY * 0.3}px)`;
    }

    scrollTicking = false;
}
window.addEventListener('scroll', () => {
    if (!scrollTicking) {
        requestAnimationFrame(onScrollFrame);
        scrollTicking = true;
    }
}, { passive: true });

/* ============================================================
   4. ANIMATED COUNTERS
   ============================================================ */
function initCounters() {
    const counters = document.querySelectorAll('[data-count]');
    counters.forEach(counter => {
        const target = parseInt(counter.getAttribute('data-count'), 10);
        const duration = 2000;
        const step = target / (duration / 16);
        let current = 0;

        const update = () => {
            current += step;
            if (current < target) {
                counter.textContent = Math.floor(current);
                requestAnimationFrame(update);
            } else {
                counter.textContent = target;
            }
        };
        update();
    });
}

/* ============================================================
   5. ARTIST GENRE FILTER
   ============================================================ */
const filterBtns = document.querySelectorAll('.filter-btn');
const artistItems = document.querySelectorAll('.artist-item');

filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        // Update active button
        filterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        const filter = btn.getAttribute('data-filter');

        artistItems.forEach(item => {
            if (filter === 'all' || item.getAttribute('data-genre') === filter) {
                item.classList.remove('hidden');
                item.style.animation = 'fadeInUp 0.4s ease forwards';
            } else {
                item.classList.add('hidden');
            }
        });
    });
});

/* ============================================================
   6. VIDEO MODAL
   ============================================================ */
const videoModal = document.getElementById('videoModal');
const videoFrame = document.getElementById('videoFrame');

if (videoModal && videoFrame) {
    const videoTriggers = document.querySelectorAll('.video-play-overlay');

    videoTriggers.forEach(trigger => {
        trigger.addEventListener('click', () => {
            const videoUrl = trigger.getAttribute('data-video');
            if (videoUrl) {
                videoFrame.src = videoUrl + '?autoplay=1&rel=0';
                const modal = new bootstrap.Modal(videoModal);
                modal.show();
            }
        });
    });

    // Stop video on modal close
    videoModal.addEventListener('hidden.bs.modal', () => {
        videoFrame.src = '';
    });
}

/* ============================================================
   7. MUSIC PLAYER (UI Demo — no real audio file required)
   ============================================================ */
const playPauseBtn = document.getElementById('playPauseBtn');
const playIcon     = document.getElementById('playIcon');
const progressFill = document.getElementById('progressFill');
const currentTimeEl = document.getElementById('currentTime');
const totalTimeEl   = document.getElementById('totalTime');
const progressBar   = document.getElementById('progressBar');

let isPlaying = false;
let progress  = 0;
let playerInterval = null;
const totalSeconds = 227; // 3:47

function formatTime(secs) {
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
}

if (playPauseBtn) {
    playPauseBtn.addEventListener('click', () => {
        isPlaying = !isPlaying;
        playIcon.className = isPlaying ? 'bi bi-pause-fill' : 'bi bi-play-fill';

        if (isPlaying) {
            playerInterval = setInterval(() => {
                progress += 1;
                if (progress >= totalSeconds) {
                    progress = 0;
                    isPlaying = false;
                    playIcon.className = 'bi bi-play-fill';
                    clearInterval(playerInterval);
                }
                const pct = (progress / totalSeconds) * 100;
                if (progressFill) progressFill.style.width = pct + '%';
                if (currentTimeEl) currentTimeEl.textContent = formatTime(progress);
            }, 1000);
        } else {
            clearInterval(playerInterval);
        }
    });
}

// Click on progress bar to seek
if (progressBar) {
    progressBar.addEventListener('click', (e) => {
        const rect = progressBar.getBoundingClientRect();
        const pct = (e.clientX - rect.left) / rect.width;
        progress = Math.floor(pct * totalSeconds);
        if (progressFill) progressFill.style.width = (pct * 100) + '%';
        if (currentTimeEl) currentTimeEl.textContent = formatTime(progress);
    });
}

// Volume control
const volumeRange = document.getElementById('volumeRange');
if (volumeRange) {
    volumeRange.addEventListener('input', () => {
        // Volume UI only (no real audio)
        const vol = volumeRange.value;
        const volIcon = volumeRange.previousElementSibling;
        if (volIcon) {
            if (vol == 0) volIcon.className = 'bi bi-volume-mute text-muted';
            else if (vol < 50) volIcon.className = 'bi bi-volume-down text-muted';
            else volIcon.className = 'bi bi-volume-up text-muted';
        }
    });
}

/* ============================================================
   8. FORM SUBMISSIONS — Supabase
   ============================================================ */
function showFormMessage(msgEl, success, text) {
    msgEl.classList.remove('d-none', 'alert-danger', 'alert-success');
    msgEl.classList.add('alert', success ? 'alert-success' : 'alert-danger');
    msgEl.textContent = text;
}

const NOT_CONFIGURED_MSG = 'This form isn\'t connected yet — the site owner needs to add Supabase credentials in assets/js/supabase-config.js.';

async function withSubmitButton(form, task) {
    const submitBtn = form.querySelector('[type="submit"]');
    const originalText = submitBtn.innerHTML;
    submitBtn.disabled = true;
    if (submitBtn.dataset.loadingText) submitBtn.innerHTML = submitBtn.dataset.loadingText;
    try {
        await task();
    } finally {
        submitBtn.innerHTML = originalText;
        submitBtn.disabled = false;
    }
}

// ---- Contact form ----
const contactForm = document.getElementById('contactForm');
const contactFormMsg = document.getElementById('contactFormMsg');
if (contactForm && contactFormMsg) {
    contactForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        if (!contactForm.checkValidity()) {
            contactForm.classList.add('was-validated');
            return;
        }
        if (!supabaseClient) { showFormMessage(contactFormMsg, false, NOT_CONFIGURED_MSG); return; }

        await withSubmitButton(contactForm, async () => {
            const fd = new FormData(contactForm);
            const { error } = await supabaseClient.from('contact_messages').insert({
                name: fd.get('name'),
                email: fd.get('email'),
                subject: fd.get('subject'),
                message: fd.get('message'),
            });

            if (error) {
                showFormMessage(contactFormMsg, false, 'Something went wrong. Please try again or email us directly.');
            } else {
                showFormMessage(contactFormMsg, true, 'Your message has been sent. We\'ll be in touch within 2–3 business days.');
                contactForm.reset();
                contactForm.classList.remove('was-validated');
            }
        });
    });
}

// ---- Demo submission form (with optional audio file upload to Supabase Storage) ----
const demoForm = document.getElementById('demoForm');
const demoFormMsg = document.getElementById('demoFormMsg');
if (demoForm && demoFormMsg) {
    demoForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        if (!demoForm.checkValidity()) {
            demoForm.classList.add('was-validated');
            return;
        }
        if (!supabaseClient) { showFormMessage(demoFormMsg, false, NOT_CONFIGURED_MSG); return; }

        await withSubmitButton(demoForm, async () => {
            const fd = new FormData(demoForm);
            const file = fd.get('demo_file');
            let demoFilePath = null;

            try {
                if (file && file.size > 0) {
                    if (file.size > 20 * 1024 * 1024) {
                        showFormMessage(demoFormMsg, false, 'Demo file exceeds the 20MB limit.');
                        return;
                    }
                    const safeName = (fd.get('artist_name') || 'artist').toString()
                        .toLowerCase().replace(/[^a-z0-9_-]/g, '');
                    const path = `${safeName}_${Date.now()}_${file.name}`;
                    const { error: uploadError } = await supabaseClient.storage
                        .from('demos').upload(path, file);
                    if (uploadError) throw uploadError;
                    demoFilePath = path;
                }

                const { error } = await supabaseClient.from('demo_submissions').insert({
                    artist_name: fd.get('artist_name'),
                    real_name: fd.get('real_name'),
                    email: fd.get('email'),
                    phone: fd.get('phone') || null,
                    genre: fd.get('genre'),
                    country: fd.get('country'),
                    stream_link: fd.get('stream_link'),
                    bio: fd.get('bio') || null,
                    demo_file_path: demoFilePath,
                    terms_accepted: fd.get('terms') === 'on',
                });
                if (error) throw error;

                showFormMessage(demoFormMsg, true, 'Your demo has been submitted successfully. Our A&R team will review it within 30 days.');
                demoForm.reset();
                demoForm.classList.remove('was-validated');
            } catch (err) {
                showFormMessage(demoFormMsg, false, 'Something went wrong. Please try again or email us directly.');
            }
        });
    });
}

// ---- Newsletter form(s) ----
const newsletterForms = document.querySelectorAll('.newsletter-form');
newsletterForms.forEach(form => {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = form.querySelector('button[type="submit"]');
        const input = form.querySelector('input[name="email"]');
        const orig = btn.textContent;

        if (!supabaseClient) {
            btn.textContent = 'Not configured';
            setTimeout(() => { btn.textContent = orig; }, 3000);
            return;
        }

        btn.textContent = '...';
        btn.disabled = true;
        const { error } = await supabaseClient.from('newsletter_subscribers')
            .insert({ email: input.value });

        // Postgres unique-violation code = already subscribed, treat as success
        if (!error || error.code === '23505') {
            btn.textContent = '✓ Subscribed';
            btn.style.background = '#22c55e';
            input.value = '';
        } else {
            btn.textContent = 'Try again';
            btn.style.background = '#dc3545';
        }
        setTimeout(() => { btn.textContent = orig; btn.style.background = ''; btn.disabled = false; }, 3000);
    });
});

/* ============================================================
   9. BACK TO TOP (visibility handled by the shared scroll listener above)
   ============================================================ */
if (backToTopBtn) {
    backToTopBtn.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
}

/* ============================================================
   10. SMOOTH SCROLL FOR ANCHOR LINKS
   ============================================================ */
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
        const target = document.querySelector(anchor.getAttribute('href'));
        if (target) {
            e.preventDefault();
            const offset = 80;
            const top = target.getBoundingClientRect().top + window.scrollY - offset;
            window.scrollTo({ top, behavior: 'smooth' });
        }
    });
});

/* ============================================================
   11. PARALLAX HERO (handled by the shared scroll listener above)
   ============================================================ */

/* ============================================================
   12. FEATURED PLAY BUTTON (Hero Release)
   ============================================================ */
const featuredPlayBtn = document.getElementById('featuredPlayBtn');
if (featuredPlayBtn) {
    featuredPlayBtn.addEventListener('click', () => {
        if (playPauseBtn) playPauseBtn.click();
        // Scroll to player
        const player = document.getElementById('musicPlayer');
        if (player) player.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
}

/* ============================================================
   13. FADE-IN ANIMATION FOR FILTERED ITEMS
   ============================================================ */
const style = document.createElement('style');
style.textContent = `
@keyframes fadeInUp {
    from { opacity: 0; transform: translateY(20px); }
    to   { opacity: 1; transform: translateY(0); }
}`;
document.head.appendChild(style);

console.log('%cOFF-LIMITS ENTERTAINMENT', 'color:#bc13fe;font-size:20px;font-weight:bold;font-family:monospace;');
console.log('%cWe don\'t follow rules. We write them.', 'color:#888;font-size:12px;');

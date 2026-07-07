/**
 * OFF-LIMITS ENTERTAINMENT — Live Abuja, Nigeria clock
 * Populates any element with [data-abuja-clock] with the current date/time
 * in Africa/Lagos (WAT, UTC+1), updated every second.
 */
'use strict';

(function () {
    const formatter = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Africa/Lagos',
        weekday: 'short', month: 'short', day: 'numeric',
        hour: 'numeric', minute: '2-digit', second: '2-digit', hour12: true,
    });

    function tick() {
        const parts = formatter.formatToParts(new Date());
        const get = (type) => parts.find(p => p.type === type)?.value || '';
        const text = `Abuja, Nigeria · ${get('weekday')} ${get('month')} ${get('day')} · ${get('hour')}:${get('minute')}:${get('second')} ${get('dayPeriod')}`;
        document.querySelectorAll('[data-abuja-clock]').forEach(el => { el.textContent = text; });
    }

    tick();
    setInterval(tick, 1000);
})();

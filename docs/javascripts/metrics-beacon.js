/* Privacy-first metrics beacon for the Site Metrics dashboard.
 *
 * No-ops unless the page carries <meta name="metrics-endpoint"> (only emitted
 * when METRICS_ENDPOINT is set at build time; empty in prod until the real
 * stack deploys). Fire-and-forget — this script must never block, throw, or
 * break the page.
 *
 * Events (POST /event, all whitelisted server-side):
 *   pageview  — every page load
 *   click     — outbound CTA clicks (external links + mailto)
 *   webvitals — LCP / INP / CLS (PerformanceObserver, best-effort)
 *   timing    — TTFB / DOM ready / full load (navigation timing)
 * Every event carries an anonymous visitor id (localStorage, no cookies) and a
 * coarse device class (parsed client-side — the raw user agent never leaves
 * the browser). Do Not Track is honored.
 */
(function () {
  var meta = document.querySelector('meta[name="metrics-endpoint"]');
  if (!meta) return;
  var endpoint = (meta.getAttribute("content") || "").trim().replace(/\/+$/, "");
  if (!endpoint) return;
  if (navigator.doNotTrack === "1") return;

  // The metrics dashboard doesn't track itself — the landing page and the
  // analytics page would otherwise self-inflate their own pageview/vitals
  // counts. Matches /metrics/ and /metrics/analytics/ in any locale.
  if (/\/(?:es\/|zh\/)?metrics(?:\/analytics)?\/?$/.test(location.pathname)) return;

  // Anonymous visitor id — localStorage only, no cookies, no identity.
  var VKEY = "__mp_visitor";
  var visitor = "";
  try {
    visitor = localStorage.getItem(VKEY) || "";
    if (!visitor) {
      visitor = (window.crypto && crypto.randomUUID)
        ? crypto.randomUUID()
        : ("v-" + Date.now() + "-" + Math.random().toString(36).slice(2));
      localStorage.setItem(VKEY, visitor);
    }
  } catch (e) { /* localStorage unavailable — send without a visitor id */ }

  // Coarse device class — parsed here so only the class is transmitted.
  var device = "desktop";
  try {
    var ua = navigator.userAgent || "";
    if ((navigator.userAgentData && navigator.userAgentData.mobile) || /Mobi|Android|iPhone/i.test(ua)) {
      device = "mobile";
    } else if (/Tablet|iPad/i.test(ua)) {
      device = "tablet";
    }
  } catch (e) { /* keep desktop */ }

  function send(payload) {
    payload.page = location.pathname;
    payload.lang = document.documentElement.lang || "en";
    if (visitor) payload.visitor = visitor;
    if (device) payload.device = device;
    try {
      fetch(endpoint + "/event", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        keepalive: true,
      }).catch(function () { /* best-effort beacon */ });
    } catch (e) { /* never break the page */ }
  }

  function onReady(fn) {
    if (document.readyState === "complete") fn();
    else window.addEventListener("load", fn, { once: true });
  }

  // Pageview
  onReady(function () { send({ type: "pageview" }); });

  // Page load timing (navigation timing)
  onReady(function () {
    var nav = performance.getEntriesByType && performance.getEntriesByType("navigation")[0];
    if (!nav) return;
    var s = nav.startTime || 0;
    var ttfb = Math.round((nav.responseStart || 0) - s);
    var dcl = Math.round((nav.domContentLoadedEventStart || 0) - s);
    var load = Math.round((nav.loadEventStart || 0) - s);
    if (ttfb > 0 || dcl > 0) send({ type: "timing", ttfb: ttfb, dcl: dcl, load: load });
  });

  // Outbound CTA clicks (external links + mailto) — capture phase
  document.addEventListener("click", function (ev) {
    var a = ev.target && ev.target.closest ? ev.target.closest("a") : null;
    if (!a) return;
    var href = a.getAttribute("href") || "";
    var target = "";
    if (/^mailto:/i.test(href)) {
      target = "email";
    } else if (/^https?:\/\//i.test(href)) {
      try { target = new URL(href).hostname.replace(/^www\./, ""); } catch (e) { return; }
    } else {
      return; // internal link — not a CTA
    }
    send({ type: "click", target: target });
  }, true);

  // Core Web Vitals — LCP / INP / CLS (best-effort observers)
  var lcpValue = null;
  var clsValue = 0;
  var inpValue = 0;
  var vitalsSent = false;
  try {
    if (window.PerformanceObserver) {
      try {
        new PerformanceObserver(function (list) {
          var entries = list.getEntries();
          if (entries.length) lcpValue = Math.round(entries[entries.length - 1].startTime);
        }).observe({ type: "largest-contentful-paint", buffered: true });
      } catch (e) { /* unsupported */ }
      try {
        new PerformanceObserver(function (list) {
          list.getEntries().forEach(function (en) {
            if (!en.hadRecentInput) clsValue += en.value;
          });
        }).observe({ type: "layout-shift", buffered: true });
      } catch (e) { /* unsupported */ }
      try {
        new PerformanceObserver(function (list) {
          list.getEntries().forEach(function (en) {
            if (en.interactionId && en.duration > inpValue) inpValue = Math.round(en.duration);
          });
        }).observe({ type: "event", buffered: true, durationThreshold: 16 });
      } catch (e) { /* unsupported */ }
    }
  } catch (e) { /* observer setup failed — skip vitals */ }

  function sendVitals() {
    if (vitalsSent) return;
    vitalsSent = true;
    if (lcpValue != null) send({ type: "webvitals", metric: "LCP", value: lcpValue });
    if (clsValue > 0) send({ type: "webvitals", metric: "CLS", value: Math.round(clsValue * 1000) / 1000 });
    if (inpValue > 0) send({ type: "webvitals", metric: "INP", value: inpValue });
  }
  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "hidden") sendVitals();
  });
  window.addEventListener("pagehide", sendVitals, { once: true });
  setTimeout(sendVitals, 15000); // safety net if the page never hides
})();

/* Site Metrics dashboard — renders live totals from GET /summary.
 *
 * Runs only on the analytics page (looks for #metrics-live) and only when a
 * metrics endpoint is configured (metrics-endpoint meta tag). Labels live in
 * the page markup so they stay translatable; this script fills the stat chips,
 * bar charts, pies, and counters. Best-effort: hides a block on any failure.
 */
(function () {
  var host = document.querySelector("#metrics-live");
  if (!host) return;
  var meta = document.querySelector('meta[name="metrics-endpoint"]');
  if (!meta) return;
  var endpoint = (meta.getAttribute("content") || "").trim().replace(/\/+$/, "");
  if (!endpoint) return;

  var PALETTE = ["#00897b", "#26a69a", "#4db6ac", "#80cbc4", "#b2dfdb", "#aed581", "#ffb74d", "#7986cb"];
  var GRAY = "#9e9e9e";

  function setText(id, value) {
    var el = document.getElementById(id);
    if (el) el.textContent = String(value);
  }

  function unhide(id) {
    var el = document.getElementById(id);
    if (el) el.hidden = false;
  }

  function renderBars(container, data) {
    container.innerHTML = "";
    var entries = Object.keys(data)
      .map(function (p) { return [p, data[p]]; })
      .sort(function (a, b) { return b[1] - a[1]; })
      .slice(0, 5);
    var max = entries.length ? entries[0][1] : 1;

    entries.forEach(function (pair) {
      var wrap = document.createElement("div");
      wrap.className = "metrics-live__bar";

      var row = document.createElement("div");
      row.className = "metrics-bar__row";
      var label = document.createElement("span");
      label.className = "metrics-bar__label";
      label.textContent = pair[0];
      var value = document.createElement("span");
      value.className = "metrics-bar__value";
      value.textContent = pair[1];
      row.appendChild(label);
      row.appendChild(value);

      var track = document.createElement("div");
      track.className = "metrics-bar__track";
      var fill = document.createElement("div");
      fill.className = "metrics-bar__fill";
      fill.style.width = Math.round((pair[1] / max) * 100) + "%";
      track.appendChild(fill);

      wrap.appendChild(row);
      wrap.appendChild(track);
      container.appendChild(wrap);
    });
  }

  function renderPie(pieEl, legendEl, data) {
    pieEl.innerHTML = "";
    legendEl.innerHTML = "";
    var entries = Object.keys(data)
      .map(function (k) { return [k, data[k]]; })
      .sort(function (a, b) { return b[1] - a[1]; });
    var total = entries.reduce(function (s, e) { return s + e[1]; }, 0);
    if (!total) return;

    var stops = [];
    var acc = 0;
    entries.forEach(function (entry, i) {
      var key = entry[0];
      var color = key === "unknown" ? GRAY : PALETTE[i % PALETTE.length];
      var pct = (entry[1] / total) * 100;
      stops.push(color + " " + acc.toFixed(2) + "% " + (acc + pct).toFixed(2) + "%");
      acc += pct;

      var li = document.createElement("li");
      var swatch = document.createElement("span");
      swatch.className = "metrics-pie-legend__swatch";
      swatch.style.background = color;
      var text = document.createElement("span");
      text.textContent = key + " — " + entry[1] + " (" + Math.round(pct) + "%)";
      li.appendChild(swatch);
      li.appendChild(text);
      legendEl.appendChild(li);
    });

    pieEl.style.background = "conic-gradient(" + stops.join(", ") + ")";
  }

  function setVital(valueId, dotId, value, unit, goodThreshold) {
    if (value === null || value === undefined) return;
    var el = document.getElementById(valueId);
    if (el) el.textContent = value + (unit ? " " + unit : "");
    var dot = document.getElementById(dotId);
    if (dot) dot.className = "pv-dot pv-dot--" + (value <= goodThreshold ? "good" : "warn");
  }

  fetch(endpoint + "/summary", { headers: { Accept: "application/json" }, cache: "no-store" })
    .then(function (res) { return res.ok ? res.json() : Promise.reject(); })
    .then(function (data) {
      var byPage = data.by_page || {};
      var byLang = data.by_lang || {};
      var byCountry = data.by_country || {};

      // Page views (pageview events only — total also includes clicks/web-vitals/timing)
      var pageviews = (data.by_type && data.by_type.pageview) || 0;
      setText("metrics-total", pageviews);
      setText("metrics-langs", Object.keys(byLang).length);
      setText("metrics-pages", Object.keys(byPage).length);
      var topEl = document.getElementById("metrics-top");
      if (topEl) renderBars(topEl, byPage);
      var langPie = document.getElementById("metrics-langs-pie");
      var langLegend = document.getElementById("metrics-langs-legend");
      if (langPie && langLegend) renderPie(langPie, langLegend, byLang);
      unhide("metrics-live");

      // Geo
      var geoHost = document.getElementById("metrics-geo");
      if (geoHost) {
        var realGeo = Object.keys(byCountry).some(function (k) { return k !== "unknown"; });
        if (realGeo) {
          var geoPie = document.getElementById("metrics-geo-pie");
          var geoLegend = document.getElementById("metrics-geo-legend");
          if (geoPie && geoLegend) renderPie(geoPie, geoLegend, byCountry);
          var geoMap = document.getElementById("metrics-geo-map");
          if (geoMap && window.renderGeoMap) {
            renderGeoMap(geoMap, byCountry);
            geoMap.hidden = false;
          }
        } else {
          var note = document.getElementById("metrics-geo-note");
          if (note) note.hidden = false;
        }
        geoHost.hidden = false;
      }

      // CTA clicks
      var clicksBars = document.getElementById("metrics-clicks-bars");
      if (clicksBars) renderBars(clicksBars, data.clicks || {});
      unhide("metrics-clicks");

      // Core Web Vitals (latest value per metric)
      var vitals = data.vitals || {};
      setVital("vitals-lcp", "vitals-lcp-dot", vitals.LCP, "ms", 2500);
      setVital("vitals-inp", "vitals-inp-dot", vitals.INP, "ms", 200);
      setVital("vitals-cls", "vitals-cls-dot", vitals.CLS, "", 0.1);
      unhide("metrics-vitals");

      // Page load timing (averages)
      var timing = data.timing || {};
      if (timing.ttfb != null) setText("timing-ttfb", timing.ttfb + " ms");
      if (timing.dcl != null) setText("timing-dcl", timing.dcl + " ms");
      if (timing.load != null) setText("timing-load", timing.load + " ms");
      unhide("metrics-timing");

      // Visitors
      var visitors = data.visitors || {};
      if (visitors.unique != null) setText("visitors-unique", visitors.unique);
      if (visitors.returning_pct != null) {
        var returningPct = visitors.returning_pct;
        var newPct = 100 - returningPct;
        setText("visitors-new", "New " + newPct + "%");
        setText("visitors-returning", "Returning " + returningPct + "%");
        var newFill = document.getElementById("visitors-new-fill");
        var retFill = document.getElementById("visitors-ret-fill");
        if (newFill) newFill.style.width = newPct + "%";
        if (retFill) retFill.style.width = returningPct + "%";
        unhide("visitors-ratio-row");
        unhide("visitors-ratio");
      }
      unhide("metrics-visitors");

      // Sessions
      var sessions = data.sessions || {};
      if (sessions.count != null) setText("sessions-count", sessions.count);
      if (sessions.pages_per_session != null) setText("sessions-pages", sessions.pages_per_session);
      if (sessions.avg_duration != null) {
        var dur = sessions.avg_duration;
        var label = dur >= 60 ? Math.round(dur / 60) + "m " + (dur % 60) + "s" : dur + "s";
        setText("sessions-duration", label);
      }
      if (sessions.bounce != null) setText("sessions-bounce", sessions.bounce + "%");
      unhide("metrics-sessions");
    })
    .catch(function () {
      host.hidden = true;
      var geoHost = document.getElementById("metrics-geo");
      if (geoHost) geoHost.hidden = true;
    });
})();

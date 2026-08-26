---
icon: material/account-eye
hide:
  - toc
---

# Visitor Analytics

How visitors use the site, measured privacy-first. A first-party beacon records page views, outbound clicks, page timing, and Core Web Vitals; every event carries just the page path, language, a coarse device class, and an anonymous visitor id (localStorage — no cookies). No IPs are stored, referrers aren't collected, and raw events expire after 90 days (DynamoDB TTL). Geo comes from CloudFront request headers, never from the visitor's IP.

<div class="metrics-stack" markdown>

<div class="metrics-stat" markdown>

### :material-account-eye: Total page views

Totals across every page and language, updated live from the metrics API.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-live" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="metrics-total">–</b><span>Total</span></div>
<div class="metrics-live__stat"><b id="metrics-langs">–</b><span>Languages</span></div>
<div class="metrics-live__stat"><b id="metrics-pages">–</b><span>Pages</span></div>
</div>

<div class="metrics-live__cols">
<div>
<p class="metrics-live__label">Top pages</p>
<div id="metrics-top"></div>
</div>
<div>
<p class="metrics-live__label">By language</p>
<div class="metrics-pie-wrap">
<div class="metrics-pie" id="metrics-langs-pie"></div>
<ul class="metrics-pie-legend" id="metrics-langs-legend"></ul>
</div>
</div>
</div>
</div>

</div>

<div class="metrics-stat" markdown>

### :material-earth: Geo

Visitors by country, from CloudFront geo headers in production — the pipeline stores only the country/city, never the IP.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-geo" hidden>
<div class="metrics-pie-wrap">
<div class="metrics-pie" id="metrics-geo-pie"></div>
<ul class="metrics-pie-legend" id="metrics-geo-legend"></ul>
</div>
<div class="metrics-geo-map" id="metrics-geo-map" hidden></div>
<p class="metrics-live__note" id="metrics-geo-note" hidden>Waiting for geo data — country values appear once CloudFront fronts the API in production.</p>
</div>

</div>

<div class="metrics-stat" markdown>

<div class="metrics-live__cols" markdown>

<div markdown>

### :material-arrow-top-right: CTA clicks

Outbound clicks — LinkedIn, GitHub, email.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-clicks" hidden>
<div id="metrics-clicks-bars"></div>
</div>

</div>

<div markdown>

### :material-speedometer: Core Web Vitals

LCP, INP, CLS — the latest visitor experience.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-vitals" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><div class="pv-vitals-head"><span class="pv-dot pv-dot--warn" id="vitals-lcp-dot"></span><span class="pv-vitals-name">LCP</span></div><b id="vitals-lcp">–</b></div>
<div class="metrics-live__stat"><div class="pv-vitals-head"><span class="pv-dot pv-dot--warn" id="vitals-inp-dot"></span><span class="pv-vitals-name">INP</span></div><b id="vitals-inp">–</b></div>
<div class="metrics-live__stat"><div class="pv-vitals-head"><span class="pv-dot pv-dot--warn" id="vitals-cls-dot"></span><span class="pv-vitals-name">CLS</span></div><b id="vitals-cls">–</b></div>
</div>
</div>

</div>

</div>

</div>

<div class="metrics-stat" markdown>

<div class="metrics-live__cols" markdown>

<div markdown>

### :material-timer-sand: Page load timing

Average TTFB, DOM ready, and full load.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-timing" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="timing-ttfb">–</b><span>TTFB</span></div>
<div class="metrics-live__stat"><b id="timing-dcl">–</b><span>DOM ready</span></div>
<div class="metrics-live__stat"><b id="timing-load">–</b><span>Full load</span></div>
</div>
</div>

</div>

<div markdown>

### :material-account-multiple: Visitors

Unique visitors via anonymous localStorage id — no cookies.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-visitors" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="visitors-unique">–</b><span>Unique visitors</span></div>
</div>
<div class="metrics-bar__row" id="visitors-ratio-row" hidden>
<span class="metrics-bar__label" id="visitors-new">New</span>
<span class="metrics-bar__value" id="visitors-returning">Returning</span>
</div>
<div class="pv-ratio" id="visitors-ratio" hidden>
<div class="metrics-bar__fill" id="visitors-new-fill"></div>
<div class="pv-ratio__ret" id="visitors-ret-fill"></div>
</div>
</div>

</div>

</div>

</div>

<div class="metrics-stat" markdown>

### :material-layers: Sessions

Engagement depth per visit — 30 minutes of inactivity breaks a session.

<span class="metrics-badge metrics-badge--live">Live</span>

<div class="metrics-live" id="metrics-sessions" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="sessions-count">–</b><span>Sessions</span></div>
<div class="metrics-live__stat"><b id="sessions-pages">–</b><span>Pages / session</span></div>
<div class="metrics-live__stat"><b id="sessions-duration">–</b><span>Avg duration</span></div>
<div class="metrics-live__stat"><b id="sessions-bounce">–</b><span>Bounce rate</span></div>
</div>
</div>

</div>

<div class="metrics-stat" markdown>

### :material-heart-pulse: Uptime

Availability checks against the live site, reported as a rolling 30-day average.

<span class="metrics-badge">Planned</span>

</div>

<div class="metrics-stat" markdown>

### :material-gauge: Performance

Performance budgets — build-time checks per release.

<span class="metrics-badge">Planned</span>

</div>

</div>

[Back to Site Metrics :material-chart-line:](../){ .md-button }

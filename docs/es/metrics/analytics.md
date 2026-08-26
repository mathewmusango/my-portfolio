---
icon: material/account-eye
hide:
  - toc
---

# Análisis de visitas

Cómo usan los visitantes el sitio, medido con privacidad. Un beacon de primera parte registra vistas de página, clics salientes, tiempos de carga y Core Web Vitals; cada evento incluye solo la ruta de la página, el idioma, una clase de dispositivo aproximada y un id de visitante anónimo (localStorage — sin cookies). Nunca se almacenan IP, no se recopilan referentes y los eventos sin procesar caducan a los 90 días (TTL de DynamoDB). La geolocalización proviene de las cabeceras de CloudFront, nunca de la IP del visitante.

<div class="metrics-stack" markdown>

<div class="metrics-stat" markdown>

### :material-account-eye: Total de vistas de página

Totales de cada página e idioma, actualizados en vivo desde la API de métricas.

<span class="metrics-badge metrics-badge--live">En vivo</span>

<div class="metrics-live" id="metrics-live" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="metrics-total">–</b><span>Total</span></div>
<div class="metrics-live__stat"><b id="metrics-langs">–</b><span>Idiomas</span></div>
<div class="metrics-live__stat"><b id="metrics-pages">–</b><span>Páginas</span></div>
</div>

<div class="metrics-live__cols">
<div>
<p class="metrics-live__label">Páginas principales</p>
<div id="metrics-top"></div>
</div>
<div>
<p class="metrics-live__label">Por idioma</p>
<div class="metrics-pie-wrap">
<div class="metrics-pie" id="metrics-langs-pie"></div>
<ul class="metrics-pie-legend" id="metrics-langs-legend"></ul>
</div>
</div>
</div>
</div>

</div>

<div class="metrics-stat" markdown>

### :material-earth: Geolocalización

Visitantes por país, desde las cabeceras geo de CloudFront en producción — el pipeline guarda solo el país/ciudad, nunca la IP.

<span class="metrics-badge metrics-badge--live">En vivo</span>

<div class="metrics-live" id="metrics-geo" hidden>
<div class="metrics-pie-wrap">
<div class="metrics-pie" id="metrics-geo-pie"></div>
<ul class="metrics-pie-legend" id="metrics-geo-legend"></ul>
</div>
<div class="metrics-geo-map" id="metrics-geo-map" hidden></div>
<p class="metrics-live__note" id="metrics-geo-note" hidden>Esperando datos geo — los países aparecen cuando CloudFront esté frente a la API en producción.</p>
</div>

</div>

<div class="metrics-stat" markdown>

<div class="metrics-live__cols" markdown>

<div markdown>

### :material-arrow-top-right: Clics en CTA

Clics salientes — LinkedIn, GitHub, correo.

<span class="metrics-badge metrics-badge--live">En vivo</span>

<div class="metrics-live" id="metrics-clicks" hidden>
<div id="metrics-clicks-bars"></div>
</div>

</div>

<div markdown>

### :material-speedometer: Core Web Vitals

LCP, INP, CLS — la experiencia más reciente del visitante.

<span class="metrics-badge metrics-badge--live">En vivo</span>

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

### :material-timer-sand: Tiempos de carga

TTFB medio, DOM listo y carga completa.

<span class="metrics-badge metrics-badge--live">En vivo</span>

<div class="metrics-live" id="metrics-timing" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="timing-ttfb">–</b><span>TTFB</span></div>
<div class="metrics-live__stat"><b id="timing-dcl">–</b><span>DOM listo</span></div>
<div class="metrics-live__stat"><b id="timing-load">–</b><span>Carga completa</span></div>
</div>
</div>

</div>

<div markdown>

### :material-account-multiple: Visitantes

Visitantes únicos mediante un id anónimo en localStorage — sin cookies.

<span class="metrics-badge metrics-badge--live">En vivo</span>

<div class="metrics-live" id="metrics-visitors" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="visitors-unique">–</b><span>Visitantes únicos</span></div>
</div>
<div class="metrics-bar__row" id="visitors-ratio-row" hidden>
<span class="metrics-bar__label" id="visitors-new">Nuevos</span>
<span class="metrics-bar__value" id="visitors-returning">Recurrentes</span>
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

### :material-layers: Sesiones

Profundidad de interacción por visita — 30 minutos de inactividad cortan una sesión.

<span class="metrics-badge metrics-badge--live">En vivo</span>

<div class="metrics-live" id="metrics-sessions" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="sessions-count">–</b><span>Sesiones</span></div>
<div class="metrics-live__stat"><b id="sessions-pages">–</b><span>Páginas / sesión</span></div>
<div class="metrics-live__stat"><b id="sessions-duration">–</b><span>Duración media</span></div>
<div class="metrics-live__stat"><b id="sessions-bounce">–</b><span>Tasa de rebote</span></div>
</div>
</div>

</div>

<div class="metrics-stat" markdown>

### :material-heart-pulse: Disponibilidad

Comprobaciones de disponibilidad del sitio en vivo, reportadas como promedio móvil de 30 días.

<span class="metrics-badge">Planificado</span>

</div>

<div class="metrics-stat" markdown>

### :material-gauge: Rendimiento

Presupuestos de rendimiento — comprobaciones de compilación por release.

<span class="metrics-badge">Planificado</span>

</div>

</div>

[Volver a Métricas del sitio :material-chart-line:](../){ .md-button }

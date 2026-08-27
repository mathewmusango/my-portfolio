/**
 * Site-structure diagram (Site Structure page, all languages).
 *
 * Renders a trilingual mermaid flowchart into the light DOM with the site's
 * theme colors (light/dark aware), fitted so its height stays within the
 * browser window. Inline zoom controls (− / + / reset) + scrollable viewport.
 * Node labels are localized from <html lang> (en / es / zh). Features:
 *   - no underlined labels on linked nodes
 *   - per-node hover preview cards + click-to-open (new tab)
 *
 * No-op on every page that has no #site-map container.
 */
(function () {
  "use strict";

  var LABELS = {
    ROOT: { en: "my-portfolio", es: "my-portfolio", zh: "my-portfolio" },
    HOME: { en: "Home", es: "Inicio", zh: "首页" },
    ABOUT: { en: "About", es: "Sobre mí", zh: "关于我" },
    EXP: { en: "Professional Experience", es: "Experiencia Profesional", zh: "专业经验" },
    SKILLS: { en: "Technical Expertise", es: "Competencias Técnicas", zh: "技术专长" },
    PROJ: { en: "Projects", es: "Proyectos", zh: "项目" },
    P1: { en: "Cloud & Migrations", es: "Nube y Migraciones", zh: "云与迁移" },
    P2: { en: "Observability & Monitoring", es: "Observabilidad y Monitoreo", zh: "可观测性与监控" },
    P3: { en: "Security & Resilience", es: "Seguridad y Resiliencia", zh: "安全与弹性" },
    P4: { en: "Platform Engineering", es: "Ingeniería de Plataformas", zh: "平台工程" },
    P5: { en: "Knowledge & Collaboration", es: "Conocimiento y Colaboración", zh: "知识与协作" },
    CERTS: { en: "Certifications", es: "Certificaciones", zh: "认证" },
    RESUME: { en: "Resume", es: "Currículum", zh: "简历" },
    CONTACT: { en: "Contact", es: "Contacto", zh: "联系我" },
    METRICS: { en: "Site Metrics", es: "Métricas del sitio", zh: "站点指标" },
    CF: { en: "Amazon CloudFront", es: "Amazon CloudFront", zh: "Amazon CloudFront" },
    API: { en: "API Gateway", es: "API Gateway", zh: "API 网关" },
    W: { en: "Lambda · writer", es: "Lambda · escritor", zh: "Lambda · 写入" },
    R: { en: "Lambda · reader", es: "Lambda · lector", zh: "Lambda · 读取" },
    DDB: { en: "Amazon DynamoDB", es: "Amazon DynamoDB", zh: "Amazon DynamoDB" },
    ATLAS: { en: "Site Atlas", es: "Atlas del sitio", zh: "站点图谱" },
    A2: { en: "Release Timeline", es: "Cronología de Versiones", zh: "版本时间线" },
    A3: { en: "Tags", es: "Etiquetas", zh: "标签" },
    A4: { en: "Site Structure", es: "Estructura del Sitio", zh: "站点结构" },
  };

  var EDGES = [
    ["ROOT", "HOME"],
    ["HOME", "ABOUT"],
    ["HOME", "EXP"],
    ["HOME", "SKILLS"],
    ["HOME", "PROJ"],
    ["PROJ", "P1"],
    ["PROJ", "P2"],
    ["PROJ", "P3"],
    ["PROJ", "P4"],
    ["PROJ", "P5"],
    ["HOME", "CERTS"],
    ["HOME", "RESUME"],
    ["HOME", "CONTACT"],
    ["ROOT", "METRICS"],
    ["ROOT", "ATLAS"],
    ["ATLAS", "A2"],
    ["ATLAS", "A3"],
    ["ATLAS", "A4"],
    // The analytics stack behind Site Metrics — connected into the same diagram.
    ["METRICS", "CF"],
    ["CF", "API"],
    ["API", "W"],
    ["API", "R"],
    ["W", "DDB"],
    ["R", "DDB"],
  ];

  var URLS = {
    ROOT: "/my-portfolio/",
    HOME: "/my-portfolio/",
    ABOUT: "/my-portfolio/about/",
    EXP: "/my-portfolio/experience/",
    SKILLS: "/my-portfolio/skills/",
    PROJ: "/my-portfolio/projects/",
    P1: "/my-portfolio/projects/cloud-migrations/",
    P2: "/my-portfolio/projects/observability/",
    P3: "/my-portfolio/projects/security-resilience/",
    P4: "/my-portfolio/projects/platform-engineering/",
    P5: "/my-portfolio/projects/knowledge-collaboration/",
    CERTS: "/my-portfolio/certifications/",
    RESUME: "/my-portfolio/resume/",
    CONTACT: "/my-portfolio/contact/",
    METRICS: "/my-portfolio/metrics/",
    CF: "/my-portfolio/metrics/analytics/",
    API: "/my-portfolio/metrics/",
    W: "/my-portfolio/metrics/",
    R: "/my-portfolio/metrics/",
    DDB: "/my-portfolio/metrics/",
    ATLAS: "/my-portfolio/atlas/",
    A2: "/my-portfolio/atlas/releases/",
    A3: "/my-portfolio/atlas/tags/",
    A4: "/my-portfolio/atlas/structure/",
  };

  var I18N = {
    en: { zoomIn: "Zoom in", zoomOut: "Zoom out", reset: "Reset zoom" },
    es: { zoomIn: "Acercar", zoomOut: "Alejar", reset: "Restablecer zoom" },
    zh: { zoomIn: "放大", zoomOut: "缩小", reset: "重置缩放" },
  };

  function currentLang() {
    var lang = (document.documentElement.lang || "en").toLowerCase().split("-")[0];
    return lang === "es" || lang === "zh" ? lang : "en";
  }

  var lang = currentLang();
  var t = I18N[lang] || I18N.en;

  function label(id) {
    return LABELS[id][lang] || LABELS[id].en;
  }

  // Localized mermaid source — root first, then each edge with its target label.
  var SOURCE = ["graph LR", '    ROOT["' + label("ROOT") + '"]'];
  EDGES.forEach(function (edge) {
    SOURCE.push("    " + edge[0] + " --> " + edge[1] + '["' + label(edge[1]) + '"]');
  });
  SOURCE.push("");
  SOURCE = SOURCE.join("\n");

  // Localized nodes: id -> { label, url } (drives hover cards and clicks).
  var NODES = [];
  Object.keys(URLS).forEach(function (id) {
    NODES.push({ id: id, label: label(id), url: URLS[id] });
  });

  var host = document.getElementById("site-map");
  if (!host) return;

  var MIN = 0.5;
  var MAX = 3;
  var STEP = 0.25;
  var level = 1;
  var svgEl = null;

  function esc(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  // Toolbar + scrollable viewport
  var toolbar = document.createElement("div");
  toolbar.className = "diagram-zoom__toolbar";
  toolbar.innerHTML =
    '<button type="button" data-zoom="out" title="' + t.zoomOut + '" aria-label="' + t.zoomOut + '">−</button>' +
    '<span class="diagram-zoom__level" role="status" aria-live="polite">100%</span>' +
    '<button type="button" data-zoom="in" title="' + t.zoomIn + '" aria-label="' + t.zoomIn + '">+</button>' +
    '<button type="button" data-zoom="reset" title="' + t.reset + '" aria-label="' + t.reset + '">⟲</button>';
  var viewport = document.createElement("div");
  viewport.className = "diagram-zoom__viewport";
  host.appendChild(toolbar);
  host.appendChild(viewport);

  function applyScale() {
    if (!svgEl) return;
    svgEl.style.transform = "scale(" + level + ")";
    svgEl.style.transformOrigin = "top left";
    viewport.style.height = Math.round(svgEl.offsetHeight * level) + "px";
    var pct = toolbar.querySelector(".diagram-zoom__level");
    if (pct) pct.textContent = Math.round(level * 100) + "%";
  }

  // Fit the diagram so its height stays within the browser window.
  function fitDiagram() {
    var availW = host.clientWidth - 2;
    var maxH = Math.round(window.innerHeight * 0.75);
    var scale = Math.min(1, availW / (svgEl.offsetWidth || 1), maxH / (svgEl.offsetHeight || 1));
    level = Math.max(0.2, +scale.toFixed(3));
    applyScale();
  }

  toolbar.addEventListener("click", function (ev) {
    var btn = ev.target.closest("[data-zoom]");
    if (!btn) return;
    if (btn.getAttribute("data-zoom") === "in") {
      level = Math.min(MAX, +(level + STEP).toFixed(2));
    } else if (btn.getAttribute("data-zoom") === "out") {
      level = Math.max(MIN, +(level - STEP).toFixed(2));
    } else {
      level = 1;
    }
    applyScale();
  });

  window.addEventListener("resize", function () {
    if (!svgEl) return;
    fitDiagram();
  });

  // Hover preview card (appended to body so it escapes any overflow clipping)
  var card = document.createElement("div");
  card.className = "diagram-zoom__preview";
  card.style.display = "none";
  document.body.appendChild(card);

  function attachInteractions(svg) {
    // Mermaid names node groups <g id="…-flowchart-<NODEID>-<n>"> — match on
    // the stable suffix instead of label text (wrapped labels lose spaces).
    NODES.forEach(function (n) {
      var re = new RegExp("-" + n.id + "-\\d+$");
      var g = null;
      svg.querySelectorAll("g[id]").forEach(function (cand) {
        if (!g && re.test(cand.id)) g = cand;
      });
      if (!g) return;
      g.style.cursor = "pointer";
      g.addEventListener("mouseenter", function () {
        card.innerHTML =
          "<strong>" + esc(n.label) + "</strong><span>" + esc(n.url) + "</span>";
        card.style.display = "block";
      });
      g.addEventListener("mousemove", function (ev) {
        card.style.left = (ev.clientX + 14) + "px";
        card.style.top = (ev.clientY + 14) + "px";
      });
      g.addEventListener("mouseleave", function () {
        card.style.display = "none";
      });
      g.addEventListener("click", function () {
        window.open(n.url, "_blank", "noopener");
      });
    });
  }

  if (window.mermaid) {
    // Real colors only — mermaid derives lighter/darker variants from
    // primaryColor, so CSS var() values make the theme compiler throw.
    var dark = document.documentElement.getAttribute("data-md-color-scheme") !== "default";
    var palette = dark
      ? {
          primaryColor: "#144a43",
          primaryTextColor: "#b2dfdb",
          primaryBorderColor: "#00897b",
          lineColor: "#6fb3ab",
          labelColor: "#e0f2f1",
        }
      : {
          primaryColor: "#e0f2f1",
          primaryTextColor: "#004d40",
          primaryBorderColor: "#00897b",
          lineColor: "#4db6ac",
          labelColor: "#004d40",
        };

    function showError(err) {
      console.error("site-map render failed", err);
      host.insertAdjacentHTML(
        "beforeend",
        '<p class="diagram-zoom__error">The site-structure diagram failed to render' +
          (err && err.message ? ": " + esc(err.message) : "") +
          ".</p>"
      );
    }

    try {
      mermaid.initialize({
        startOnLoad: false,
        theme: "base",
        htmlLabels: false,
        themeVariables: {
          primaryColor: palette.primaryColor,
          primaryTextColor: palette.primaryTextColor,
          primaryBorderColor: palette.primaryBorderColor,
          lineColor: palette.lineColor,
          labelColor: palette.labelColor,
          fontFamily: getComputedStyle(document.body).fontFamily,
          fontSize: "14px",
        },
      });
      mermaid
        .render("site-map-diagram", SOURCE)
        .then(function (res) {
          viewport.insertAdjacentHTML("beforeend", res.svg);
          svgEl = viewport.querySelector("svg");
          if (!svgEl) throw new Error("no svg in render result");
          svgEl.style.maxWidth = "none";
          svgEl.style.height = "auto";
          if (res.bindFunctions) res.bindFunctions(svgEl);
          attachInteractions(svgEl);
          fitDiagram();
        })
        .catch(function (err) {
          showError(err);
        });
    } catch (err) {
      showError(err);
    }
  } else {
    host.insertAdjacentHTML(
      "beforeend",
      '<p class="diagram-zoom__error">The site-structure diagram could not load.</p>'
    );
  }
})();

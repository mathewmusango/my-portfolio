(function () {
  var bundle = window.__esbuild_esm_mermaid_nm;
  if (!bundle || !bundle.mermaid) return;
  var api = bundle.mermaid;

  var PALETTES = {
    default: {
      primaryColor: "#e8f4f2",
      primaryTextColor: "#1a1a1a",
      primaryBorderColor: "#00897b",
      lineColor: "#48606b",
      clusterBkg: "#f1f7f6",
      clusterBorder: "#b6d8d2",
      edgeLabelBackground: "#ffffff",
      titleColor: "#1a1a1a",
    },
    slate: {
      primaryColor: "#16323a",
      primaryTextColor: "#e6edf3",
      primaryBorderColor: "#26a69a",
      lineColor: "#9fb3c8",
      clusterBkg: "#0f1b22",
      clusterBorder: "#2b4b52",
      edgeLabelBackground: "#0f1b22",
      titleColor: "#e6edf3",
    },
  };

  function scheme() {
    return document.documentElement.getAttribute("data-md-color-scheme") === "slate"
      ? "slate"
      : "default";
  }

  function render(pre, index) {
    var source = pre.dataset.source || pre.textContent;
    pre.dataset.source = source;
    var key = scheme();
    api.initialize({
      startOnLoad: false,
      theme: "base",
      securityLevel: "loose",
      themeVariables: PALETTES[key],
      flowchart: { htmlLabels: false },
    });
    api
      .render("mermaid-" + index + "-" + Math.random().toString(36).slice(2), source)
      .then(function (result) {
        pre.innerHTML = result.svg;
        pre.classList.add("mermaid--rendered");
      })
      .catch(function (error) {
        console.error("mermaid render failed", error);
      });
  }

  function renderAll() {
    var blocks = document.querySelectorAll("pre.mermaid");
    Array.prototype.forEach.call(blocks, function (pre, index) {
      if (pre.querySelector("svg")) return;
      render(pre, index);
    });
  }

  function rerenderAll() {
    var blocks = document.querySelectorAll("pre.mermaid--rendered");
    Array.prototype.forEach.call(blocks, function (pre, index) {
      pre.innerHTML = "";
      pre.classList.remove("mermaid--rendered");
      render(pre, index);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", renderAll);
  } else {
    renderAll();
  }

  new MutationObserver(function (records) {
    var changed = records.some(function (record) {
      return record.attributeName === "data-md-color-scheme";
    });
    if (changed) rerenderAll();
    else renderAll();
  }).observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["data-md-color-scheme"],
    childList: true,
    subtree: true,
  });
})();

(function () {
  Array.prototype.forEach.call(document.querySelectorAll(".mermaid"), function (el) {
    if (!el.dataset.source) el.dataset.source = el.textContent;
  });

  function api() {
    var bundle = window.__esbuild_esm_mermaid_nm;
    if (!bundle || !bundle.mermaid) return null;
    return bundle.mermaid.default || bundle.mermaid;
  }

  var CONFIG = {
    startOnLoad: false,
    theme: "base",
    look: "classic",
    securityLevel: "loose",
    flowchart: { htmlLabels: false, look: "classic" },
    themeVariables: {
      fontFamily: "inherit",
      fontSize: "14px",
      primaryColor: "#e0f2f1",
      primaryTextColor: "#00332e",
      primaryBorderColor: "#00897b",
      lineColor: "#4db6ac",
      textColor: "#00332e",
      nodeBorder: "#00897b",
      clusterBkg: "#f1f8f7",
      clusterBorder: "#b2dfdb",
      edgeLabelBackground: "#ffffff",
      labelColor: "#00332e",
    },
  };

  if (api()) api().initialize(CONFIG);

  function renderAll() {
    var mermaid = api();
    if (!mermaid) return false;
    var pending = [];

    Array.prototype.forEach.call(document.querySelectorAll(".mermaid"), function (el, index) {
      if (el.dataset.rendered === "1" || !el.dataset.source) return;
      pending.push({ el: el, index: index });
    });

    if (!pending.length) return true;

    mermaid.initialize(CONFIG);

    pending.reduce(function (chain, item) {
      return chain.then(function () {
        return mermaid
          .render(
            "mermaid-" + item.index + "-" + Math.random().toString(36).slice(2),
            item.el.dataset.source
          )
          .then(function (result) {
            item.el.innerHTML = result.svg;
            item.el.dataset.rendered = "1";
            item.el.classList.add("mermaid--rendered");
          })
          .catch(function (error) {
            console.error("mermaid render failed", error);
          });
      });
    }, Promise.resolve());

    return true;
  }

  function boot() {
    if (renderAll()) return;
    var tries = 0;
    var timer = setInterval(function () {
      tries += 1;
      if (renderAll() || tries > 60) clearInterval(timer);
    }, 250);
  }

  if (document.readyState === "complete") {
    boot();
  } else {
    window.addEventListener("load", boot);
  }
})();

(function () {
  var bundle = window.__esbuild_esm_mermaid_nm;
  if (!bundle || !bundle.mermaid) return;
  var api = bundle.mermaid;

  function scheme() {
    return "default";
  }

  function render(pre, index) {
    var source = pre.dataset.source || pre.textContent;
    pre.dataset.source = source;
    var key = scheme();
    api.initialize({
      startOnLoad: false,
      theme: "base",
      securityLevel: "loose",
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

  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", rerenderAll);

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

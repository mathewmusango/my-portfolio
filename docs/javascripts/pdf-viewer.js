// Renders the resume PDF as canvas pages inside the social card, so the
// document fills the full card width (no browser PDF viewer / zoom issues).
// Re-renders on window resize so the preview stays responsive, and overlays
// pdf.js link annotations so the PDF's own links stay clickable. Hit areas are
// derived from the real text positions (getTextContent) instead of raw
// annotation rects, because the latter can be offset/short (weasyprint hugs
// the baseline) — this keeps clickable areas aligned with the visible text.
//
// Material's "instant loading" swaps page content without a full reload, so
// DOMContentLoaded only fires once. A MutationObserver starts the viewer
// whenever #pdf-pages appears, and each container instance renders only once
// (re-navigating to the page creates a fresh container, so it re-renders).
(function () {
  var pdf = null;
  var renderToken = 0;
  var resizeTimer = null;
  var container = null;

  function start(containerEl) {
    container = containerEl;
    var url = container.getAttribute("data-pdf-url");
    if (!url || typeof pdfjsLib === "undefined") {
      container.innerHTML = '<p class="pdf-error">Resume preview unavailable.</p>';
      return;
    }

    pdfjsLib.GlobalWorkerOptions.workerSrc = "../assets/js/pdf.worker.min.js";

    var loading = document.createElement("p");
    loading.className = "pdf-loading";
    loading.textContent = "Loading resume…";
    container.appendChild(loading);

    pdfjsLib.getDocument(url).promise
      .then(function (pdfDoc) {
        pdf = pdfDoc;
        loading.remove();
        renderPages(pdf).catch(function () {
          clearPages();
          container.innerHTML = '<p class="pdf-error">Resume could not be loaded.</p>';
        });
        window.addEventListener("resize", scheduleRender);
      })
      .catch(function () {
        loading.remove();
        container.innerHTML = '<p class="pdf-error">Resume could not be loaded.</p>';
      });
  }

  function init() {
    var el = document.getElementById("pdf-pages");
    if (!el || el.getAttribute("data-pdf-initialized") === "1") return;
    el.setAttribute("data-pdf-initialized", "1");
    start(el);
  }

  function clearPages() {
    while (container.firstChild) container.removeChild(container.firstChild);
  }

  function resolveDestPage(dest) {
    if (!Array.isArray(dest) || dest.length === 0) return Promise.resolve(null);
    var first = dest[0];
    if (typeof first === "number") return Promise.resolve(first); // 1-based page
    if (first && typeof first.num === "number") {
      return pdf.getPageIndex(first).then(function (idx) {
        return idx + 1;
      });
    }
    return Promise.resolve(null);
  }

  // Text item bounding box in viewport (canvas) coordinates.
  function textBBox(item, viewport) {
    var t = item.transform;
    var top = viewport.convertToViewportPoint(t[4], t[5] + item.height);
    var bottom = viewport.convertToViewportPoint(t[4] + item.width, t[5]);
    return { left: top[0], top: top[1], right: bottom[0], bottom: bottom[1] };
  }

  function overlayLinks(page, viewport, wrap, annotations, items) {
    annotations.forEach(function (annotation) {
      if (annotation.subtype !== "Link") return;
      if (!annotation.url && !annotation.dest) return;

      var link = document.createElement("a");
      link.className = "pdf-link";

      // WeasyPrint can emit vertically inverted link rects (top > bottom).
      // Normalize, then clip matched text spans to this area so each link's
      // hit box stays precise even when one text run holds several links.
      var rect = viewport.convertToViewportRectangle(annotation.rect);
      var aBox = {
        left: Math.min(rect[0], rect[2]),
        top: Math.min(rect[1], rect[3]),
        right: Math.max(rect[0], rect[2]),
        bottom: Math.max(rect[1], rect[3])
      };
      var box = null;
      for (var i = 0; i < items.length; i++) {
        var tb = textBBox(items[i], viewport);
        var c = {
          left: Math.max(tb.left, aBox.left),
          top: Math.max(tb.top, aBox.top),
          right: Math.min(tb.right, aBox.right),
          bottom: Math.min(tb.bottom, aBox.bottom)
        };
        if (c.right <= c.left || c.bottom <= c.top) continue;
        if (!box) {
          box = c;
        } else {
          box.left = Math.min(box.left, c.left);
          box.top = Math.min(box.top, c.top);
          box.right = Math.max(box.right, c.right);
          box.bottom = Math.max(box.bottom, c.bottom);
        }
      }
      if (!box) box = aBox; // fall back to the normalized rect

      // Enforce a minimum hit area.
      var MIN_HIT = 10;
      if (box.bottom - box.top < MIN_HIT) {
        var midY = (box.top + box.bottom) / 2;
        box.top = midY - MIN_HIT / 2;
        box.bottom = midY + MIN_HIT / 2;
      }
      if (box.right - box.left < MIN_HIT) {
        var midX = (box.left + box.right) / 2;
        box.left = midX - MIN_HIT / 2;
        box.right = midX + MIN_HIT / 2;
      }
      link.style.left = box.left + "px";
      link.style.top = box.top + "px";
      link.style.width = (box.right - box.left) + "px";
      link.style.height = (box.bottom - box.top) + "px";

      if (annotation.url) {
        link.href = annotation.url;
        link.target = "_blank";
        link.rel = "noopener noreferrer";
        // Explicit window.open guarantees a new tab on a trusted click,
        // regardless of browser target-attribute handling.
        link.addEventListener("click", function (ev) {
          if (ev.button !== 0 || ev.metaKey || ev.ctrlKey || ev.shiftKey || ev.altKey) return;
          ev.preventDefault();
          window.open(annotation.url, "_blank", "noopener");
        });
      } else if (annotation.dest) {
        link.addEventListener("click", function (ev) {
          ev.preventDefault();
          resolveDestPage(annotation.dest).then(function (pageNum) {
            if (!pageNum) return;
            var target = container.children[pageNum - 1];
            if (target) target.scrollIntoView({ behavior: "smooth", block: "start" });
          });
        });
      }

      wrap.appendChild(link);
    });
  }

  function renderPages(pdfDoc) {
    var width = container.clientWidth - 1;
    var chain = Promise.resolve();
    for (var p = 1; p <= pdfDoc.numPages; p++) {
      (function (pageNum) {
        chain = chain.then(function () {
          return pdfDoc.getPage(pageNum).then(function (page) {
            var base = page.getViewport({ scale: 1 });
            var viewport = page.getViewport({ scale: width / base.width });
            var wrap = document.createElement("div");
            wrap.className = "pdf-page";
            var canvas = document.createElement("canvas");
            canvas.className = "pdf-page__canvas";
            canvas.width = viewport.width;
            canvas.height = viewport.height;
            wrap.appendChild(canvas);
            container.appendChild(wrap);
            return page
              .render({
                canvasContext: canvas.getContext("2d"),
                viewport: viewport
              })
              .promise.then(function () {
                return Promise.all([page.getAnnotations(), page.getTextContent()]);
              })
              .then(function (results) {
                overlayLinks(page, viewport, wrap, results[0], results[1].items);
              });
          });
        });
      })(p);
    }
    return chain;
  }

  function scheduleRender() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () {
      if (!pdf) return;
      var token = ++renderToken;
      clearPages();
      renderPages(pdf).catch(function () {
        if (token === renderToken) {
          container.innerHTML = '<p class="pdf-error">Resume could not be loaded.</p>';
        }
      });
    }, 150);
  }

  // Direct page load / standalone viewer.
  document.addEventListener("DOMContentLoaded", init);

  // Instant loading: content is swapped without DOMContentLoaded firing.
  if (typeof MutationObserver !== "undefined") {
    new MutationObserver(function () {
      var el = document.getElementById("pdf-pages");
      if (el && el.getAttribute("data-pdf-initialized") !== "1") init();
    }).observe(document.documentElement, { childList: true, subtree: true });
  }
})();

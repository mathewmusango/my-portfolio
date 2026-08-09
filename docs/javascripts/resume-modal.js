// Resume popup: opens the resume PDF in a modal on the same page.
// The modal is closed via the (x) button, clicking the backdrop, or Esc.
// A floating download symbol appears once the user starts interacting with
// the PDF (mouse enters, clicks into it, scrolls) or after a short delay.
// Falls back to normal navigation if JavaScript is unavailable.
(function () {
  var DOWNLOAD_NAME = "Mathew-Musango-Resume.pdf";

  var DOWNLOAD_ICON =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" ' +
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
    'stroke-linejoin="round" aria-hidden="true">' +
    '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>' +
    '<polyline points="7 10 12 15 17 10"/>' +
    '<line x1="12" y1="15" x2="12" y2="3"/></svg>';

  var EXTERNAL_ICON =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" ' +
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
    'stroke-linejoin="round" aria-hidden="true">' +
    '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>' +
    '<polyline points="15 3 21 3 21 9"/>' +
    '<line x1="10" y1="14" x2="21" y2="3"/></svg>';

  function openModal(src) {
    var overlay = document.createElement("div");
    overlay.className = "resume-modal-overlay";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.setAttribute("aria-label", "Resume");

    var modal = document.createElement("div");
    modal.className = "resume-modal";

    var close = document.createElement("button");
    close.type = "button";
    close.className = "resume-modal-close";
    close.setAttribute("aria-label", "Close resume");
    close.innerHTML = "&times;";

    var iframe = document.createElement("iframe");
    iframe.src = src;
    iframe.title = "Resume";
    iframe.className = "resume-modal-frame";
    iframe.loading = "lazy";

    var fab = document.createElement("button");
    fab.type = "button";
    fab.className = "resume-modal-fab";
    fab.setAttribute("aria-label", "Download resume");
    fab.setAttribute("data-tooltip", "Download resume");
    fab.innerHTML = DOWNLOAD_ICON;
    fab.addEventListener("click", function () {
      var link = document.createElement("a");
      link.href = src;
      link.download = DOWNLOAD_NAME;
      document.body.appendChild(link);
      link.click();
      link.remove();
    });

    var openTab = document.createElement("button");
    openTab.type = "button";
    openTab.className = "resume-modal-fab";
    openTab.setAttribute("aria-label", "Open resume in new tab");
    openTab.setAttribute("data-tooltip", "Open resume in new tab");
    openTab.innerHTML = EXTERNAL_ICON;
    openTab.addEventListener("click", function () {
      var link = document.createElement("a");
      link.href = src;
      link.target = "_blank";
      link.rel = "noopener";
      document.body.appendChild(link);
      link.click();
      link.remove();
    });

    var actions = document.createElement("div");
    actions.className = "resume-modal-actions";
    actions.appendChild(fab);
    actions.appendChild(openTab);

    modal.appendChild(close);
    modal.appendChild(iframe);
    modal.appendChild(actions);
    overlay.appendChild(modal);
    document.body.appendChild(overlay);

    function closeModal() {
      overlay.remove();
      document.body.classList.remove("resume-modal-open");
      document.removeEventListener("keydown", onKey);
      clearTimeout(revealTimer);
    }

    function onKey(event) {
      if (event.key === "Escape") closeModal();
    }

    // The PDF viewer inside the iframe is sandboxed, so its internal scroll
    // events are not visible to this page. Reveal the download symbol on the
    // interaction triggers that do fire, plus a short fallback timer.
    var revealed = false;
    function reveal() {
      if (revealed) return;
      revealed = true;
      actions.classList.add("resume-modal-actions--show");
    }
    var revealTimer = setTimeout(reveal, 2500);
    modal.addEventListener("wheel", reveal, { passive: true });
    modal.addEventListener("touchmove", reveal, { passive: true });
    modal.addEventListener("mouseenter", reveal);
    iframe.addEventListener("focus", reveal);
    iframe.addEventListener("click", reveal);

    close.addEventListener("click", closeModal);
    overlay.addEventListener("click", function (event) {
      if (event.target === overlay) closeModal();
    });
    document.addEventListener("keydown", onKey);
    document.body.classList.add("resume-modal-open");

    close.focus();
  }

  document.addEventListener("click", function (event) {
    var link = event.target.closest("a.resume-popup");
    if (link) {
      event.preventDefault();
      openModal(link.getAttribute("href"));
    }
  });

  // Resume page inline viewer actions: download / open in new tab
  document.addEventListener("click", function (event) {
    var btn = event.target.closest("button[data-page-action]");
    if (!btn) return;
    var url = btn.getAttribute("data-page-src") || "";
    if (btn.getAttribute("data-page-action") === "download") {
      var link = document.createElement("a");
      link.href = url;
      link.download = DOWNLOAD_NAME;
      document.body.appendChild(link);
      link.click();
      link.remove();
    } else {
      window.open(url, "_blank", "noopener");
    }
  });
})();

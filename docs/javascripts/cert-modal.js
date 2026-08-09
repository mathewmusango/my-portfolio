// Certification popup: opens a credential in an iframe modal on the same page,
// with an "open in new tab" option. Credly's /embedded_badge endpoint allows
// framing (frame-ancestors *), unlike the full badge page. Coursera blocks
// framing entirely, so those links open straight in a new tab instead.
(function () {
  var EXTERNAL_ICON =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" ' +
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
    'stroke-linejoin="round" aria-hidden="true">' +
    '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>' +
    '<polyline points="15 3 21 3 21 9"/>' +
    '<line x1="10" y1="14" x2="21" y2="3"/></svg>';

  function openCertModal(embedUrl, title, newTabUrl) {
    var overlay = document.createElement("div");
    overlay.className = "resume-modal-overlay";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.setAttribute("aria-label", title);

    var modal = document.createElement("div");
    modal.className = "resume-modal cert-modal";

    var close = document.createElement("button");
    close.type = "button";
    close.className = "resume-modal-close";
    close.setAttribute("aria-label", "Close");
    close.innerHTML = "&times;";

    var iframe = document.createElement("iframe");
    iframe.src = embedUrl;
    iframe.title = title;
    iframe.className = "resume-modal-frame";
    iframe.loading = "lazy";

    var fab = document.createElement("button");
    fab.type = "button";
    fab.className = "resume-modal-fab";
    fab.setAttribute("aria-label", "Open in new tab");
    fab.setAttribute("data-tooltip", "Open in new tab");
    fab.innerHTML = EXTERNAL_ICON;
    fab.addEventListener("click", function () {
      var link = document.createElement("a");
      link.href = newTabUrl;
      link.target = "_blank";
      link.rel = "noopener";
      document.body.appendChild(link);
      link.click();
      link.remove();
    });

    var actions = document.createElement("div");
    actions.className = "resume-modal-actions resume-modal-actions--show";
    actions.appendChild(fab);

    modal.appendChild(close);
    modal.appendChild(iframe);
    modal.appendChild(actions);
    overlay.appendChild(modal);
    document.body.appendChild(overlay);
    document.body.classList.add("resume-modal-open");

    function closeModal() {
      overlay.remove();
      document.body.classList.remove("resume-modal-open");
      document.removeEventListener("keydown", onKey);
    }

    function onKey(event) {
      if (event.key === "Escape") closeModal();
    }

    close.addEventListener("click", closeModal);
    overlay.addEventListener("click", function (event) {
      if (event.target === overlay) closeModal();
    });
    document.addEventListener("keydown", onKey);
    close.focus();
  }

  document.addEventListener("click", function (event) {
    var link = event.target.closest("a[data-embed-url]");
    if (!link) return;
    event.preventDefault();
    openCertModal(
      link.getAttribute("data-embed-url"),
      link.getAttribute("data-cert-title") || "Certification",
      link.href
    );
  });
})();

// Profile photo lightbox (home page hero only).
// Clicking the profile picture opens it in a fullscreen overlay, closed via
// the (x) button, clicking the backdrop, or pressing Esc. The button only
// exists on the home page, so this is a no-op everywhere else.
(function () {
  if (!document.querySelector("button[data-lightbox-src]")) return;

  document.addEventListener("click", function (event) {
    var btn = event.target.closest("button[data-lightbox-src]");
    if (!btn) return;
    event.preventDefault();

    var src = btn.getAttribute("data-lightbox-src");
    if (!src) return;

    var overlay = document.createElement("div");
    overlay.className = "hero-lightbox-overlay";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.setAttribute("aria-label", "Profile photo");

    var img = document.createElement("img");
    img.className = "hero-lightbox-img";
    img.src = src;
    img.alt = "Mathew Musango Peter";

    var close = document.createElement("button");
    close.type = "button";
    close.className = "hero-lightbox-close";
    close.setAttribute("aria-label", "Close");
    close.innerHTML = "&times;";

    overlay.appendChild(close);
    overlay.appendChild(img);
    document.body.appendChild(overlay);
    document.body.classList.add("hero-lightbox-open");

    function closeModal() {
      overlay.remove();
      document.body.classList.remove("hero-lightbox-open");
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
  });
})();

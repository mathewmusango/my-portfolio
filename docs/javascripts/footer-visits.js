/* Footer page-visits counter — shows the CURRENT page's view count.
 *
 * Reads the metrics endpoint from the meta tag (no-op when unset), asks
 * GET /views?page=<current path> (a Query on the page-date GSI, no scan) with
 * cache bypass, and fills #page-visits with a localized label. Best-effort —
 * never breaks the page.
 */
(function () {
  var meta = document.querySelector('meta[name="metrics-endpoint"]');
  if (!meta) return;
  var endpoint = (meta.getAttribute("content") || "").trim().replace(/\/+$/, "");
  if (!endpoint) return;

  var host = document.getElementById("page-visits");
  if (!host) return;

  var labels = { en: "Page Visits:", es: "Visitas de página:", zh: "页面访问量：" };
  var label = labels[document.documentElement.lang] || "Page Visits:";

  fetch(endpoint + "/views?page=" + encodeURIComponent(location.pathname), {
    headers: { Accept: "application/json" },
    cache: "no-store",
  })
    .then(function (res) { return res.ok ? res.json() : Promise.reject(); })
    .then(function (data) {
      host.textContent = label + " " + (data.views || 0);
      host.hidden = false;
    })
    .catch(function () { /* best-effort footer counter */ });
})();

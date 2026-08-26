/* Tags index — keeps each tag heading with its page list inside the
 * multi-column layout. The tags plugin emits flat <h2><ul> siblings; wrapping
 * each pair in a break-inside:avoid container stops the heading from landing
 * at the bottom of one column while its list flows into the next.
 *
 * NOTE: iterate a static NodeList (:scope > h2, ul). The old version walked
 * the LIVE children collection while insertBefore-ing wrappers, which shifted
 * indices and skipped every second pair (e.g. the DR tag). */
(function () {
  var grid = document.querySelector(".tags-grid");
  if (!grid) return;

  var items = [];
  var current = null;
  Array.prototype.forEach.call(
    grid.querySelectorAll(":scope > h2, :scope > ul"),
    function (el) {
      if (el.tagName === "H2") {
        current = document.createElement("div");
        current.className = "tags-item";
        items.push(current);
        current.appendChild(el);
      } else if (el.tagName === "UL" && current) {
        current.appendChild(el);
        current = null;
      }
    }
  );
  items.forEach(function (item) {
    grid.appendChild(item);
  });
})();

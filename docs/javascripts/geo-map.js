/* Geo access-point map — equirectangular dot map, fully self-hosted.
 *
 * Renders a faint world of country-centroid dots, then highlights visited
 * countries with teal dots sized by visit count (sqrt scale). Pure inline SVG:
 * no tiles, no third-party requests. Exposed as window.renderGeoMap(container,
 * byCountry) — called by metrics-live.js (real data) and metrics-preview.js
 * (sample data).
 */
(function () {
  // ISO 3166-1 alpha-2 → [lat, lon] country centroids (approximate).
  var CENTROIDS = {
    "KE": [1.29, 36.82], "UG": [1.37, 32.29], "TZ": [-6.37, 34.89], "ET": [9.15, 40.49],
    "NG": [9.08, 8.68], "GH": [7.95, -1.02], "ZA": [-30.56, 22.94], "MA": [31.79, -7.09],
    "DZ": [28.03, 1.66], "EG": [26.82, 30.8], "RW": [-1.94, 29.87], "ZW": [-19.02, 29.15],
    "US": [39.83, -98.58], "CA": [56.13, -106.35], "MX": [23.63, -102.55],
    "BR": [-14.24, -51.93], "AR": [-38.42, -63.62], "CO": [4.57, -74.3],
    "CL": [-35.68, -71.54], "PE": [-9.19, -75.02],
    "GB": [54.0, -2.0], "DE": [51.17, 10.45], "FR": [46.23, 2.21], "ES": [40.46, -3.75],
    "IT": [41.87, 12.57], "NL": [52.13, 5.29], "BE": [50.5, 4.47], "CH": [46.82, 8.23],
    "SE": [60.13, 18.64], "NO": [60.47, 8.47], "DK": [56.26, 9.5], "FI": [61.92, 25.75],
    "IE": [53.14, -8.24], "PT": [39.4, -8.22], "PL": [51.92, 19.15], "CZ": [49.82, 15.47],
    "AT": [47.52, 14.55], "HU": [47.16, 19.5], "RO": [45.94, 24.97], "GR": [39.07, 21.82],
    "TR": [38.96, 35.24], "RU": [61.52, 105.32], "UA": [48.38, 31.17],
    "IN": [20.59, 78.96], "CN": [35.86, 104.2], "JP": [36.2, 138.25], "KR": [35.91, 127.77],
    "SG": [1.35, 103.82], "MY": [4.21, 101.98], "ID": [-0.79, 113.92], "TH": [15.87, 100.99],
    "VN": [14.06, 108.28], "PH": [12.88, 121.77], "PK": [30.38, 69.35], "BD": [23.68, 90.36],
    "LK": [7.87, 80.77], "AE": [23.42, 53.85], "SA": [23.89, 45.08], "IL": [31.05, 34.85],
    "QA": [25.35, 51.18], "AU": [-25.27, 133.78], "NZ": [-40.9, 174.89],
  };

  var NS = "http://www.w3.org/2000/svg";
  var W = 800;
  var H = 400;

  function project(lat, lon) {
    return { x: ((lon + 180) / 360) * W, y: ((90 - lat) / 180) * H };
  }

  function circle(attrs, className) {
    var c = document.createElementNS(NS, "circle");
    Object.keys(attrs).forEach(function (k) { c.setAttribute(k, attrs[k]); });
    if (className) c.setAttribute("class", className);
    return c;
  }

  window.renderGeoMap = function (container, byCountry) {
    var svg = document.createElementNS(NS, "svg");
    svg.setAttribute("viewBox", "0 0 " + W + " " + H);
    svg.setAttribute("class", "metrics-geo-map__svg");
    svg.setAttribute("role", "img");
    svg.setAttribute("aria-label", "World map of visitor access points");

    // Faint world — every known country's centroid.
    Object.keys(CENTROIDS).forEach(function (code) {
      var p = project(CENTROIDS[code][0], CENTROIDS[code][1]);
      svg.appendChild(circle({ cx: p.x, cy: p.y, r: 2.2 }, "metrics-geo-map__dot--bg"));
    });

    // Access points — visited countries, sized by visit count.
    var counts = [];
    Object.keys(byCountry || {}).forEach(function (code) {
      if (code !== "unknown" && CENTROIDS[code]) counts.push([code, byCountry[code]]);
    });
    var max = counts.reduce(function (m, e) { return Math.max(m, e[1]); }, 1);
    counts.forEach(function (entry) {
      var p = project(CENTROIDS[entry[0]][0], CENTROIDS[entry[0]][1]);
      var dot = circle({
        cx: p.x,
        cy: p.y,
        r: String(3 + 9 * Math.sqrt(entry[1] / max)),
      }, "metrics-geo-map__dot");
      var title = document.createElementNS(NS, "title");
      title.textContent = entry[0] + " — " + entry[1];
      dot.appendChild(title);
      svg.appendChild(dot);
    });

    container.innerHTML = "";
    container.appendChild(svg);
  };
})();

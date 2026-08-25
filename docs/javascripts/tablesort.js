/**
 * Sortable data tables (Material reference: Data tables).
 *
 * Tablesort is natively integrated with Material — this initializes it on
 * every data table (article tables without a class), so columns become
 * click-to-sort. The Release Timeline's first column (Version) uses the
 * dotsep sort method so dotted versions compare numerically (2.10 > 2.4).
 * Fires on each document load via Material's document$ stream.
 */
document$.subscribe(function () {
  var tables = document.querySelectorAll("article table:not([class])");
  tables.forEach(function (table) {
    var versionHeader = table.querySelector("th");
    if (versionHeader) versionHeader.setAttribute("data-sort-method", "dotsep");
    new Tablesort(table);
  });
});

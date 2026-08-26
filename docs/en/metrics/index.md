---
icon: material/chart-line
hide:
  - toc
---

# Site Metrics

This site is built and operated like a production platform — version-controlled content, automated builds, and strict checks before anything ships. This page is its instrument panel: what's inside, how it's delivered, and what's measured. The only runtime instrumentation is a first-party, privacy-first beacon that sends just the page path and language — every number here is a fact, not a guess.

<div class="metrics-grid" markdown>

<div class="metrics-stat" markdown>

### :material-file-document: Pages

**{{pages_total}}**

per language, fully trilingual

</div>

<div class="metrics-stat" markdown>

### :material-translate: Languages

**3**

English · Español · 中文

</div>

<div class="metrics-stat" markdown>

### :material-update: Last updated

**{{last_updated}}**

content ships with every release

</div>

<div class="metrics-stat" markdown>

### :material-rocket-launch: Delivery

**Automated**

GitHub Actions · strict build · SBOM · Terraform IaC

</div>

</div>

## Live data

Visitor analytics — page views, languages, and top pages, collected privacy-first — live on their own page.

[View Visitor Analytics :material-account-eye:](analytics/){ .md-button .md-button--primary }

# Mathew Musango Peter

[![Mathew Musango Peter - Portfolio](https://img.shields.io/badge/Mathew_Musango_Peter_--_Portfolio-00897b?style=for-the-badge)](https://mathewmusango.github.io/my-portfolio/)

Personal portfolio site for **Mathew Musango Peter** — Platform Engineering & Infrastructure Leader.
Built with **MkDocs + Material for MkDocs**, dark-teal theme.

Live: <https://mathewmusango.github.io/my-portfolio/>

## Tech Stack

| Layer      | Tooling                                                               |
| ---------- | --------------------------------------------------------------------- |
| Site       | [MkDocs](https://www.mkdocs.org/) 1.6.1 + [Material](https://squidfunk.github.io/mkdocs-material/) 9.7.7 |
| Theme      | Material — dark slate (default), light toggle, teal `#00897b` accent   |
| Plugins    | Search (suggest/highlight), git revision dates + contributors, minify |
| PDF viewer | pdf.js (self-hosted) with clickable, new-tab links overlays            |

## Development

This is the **single source of truth** — local development and deployment both run from here.
Local development uses the live-reload dev server (`compose.yaml` → podman, backed by
`scripts/serve.py`, which also exposes a `/health` endpoint). Commits to `main` are built,
checked, and deployed automatically by GitHub Actions (below).

## CI / CD

- **CI** (`.github/workflows/ci.yml`) — on every push/PR to `main` **and `v*` tags**: shared
  build action (pip cache, `mkdocs build --strict`, `pip-audit` dependency audit, internal link
  check, CSS sanity check) with the production `site_url`; uploads the built `site/` as an
  artifact (7-day retention).
- **Deploy staging** (`.github/workflows/deploy-staging.yml`) — on CI success for `main` pushes:
  syncs the artifact to the **staging S3 bucket** (`<project>-staging-site`) + CloudFront
  invalidation (OIDC `STAGING_DEPLOY_ROLE_ARN`).
- **Deploy prod** (`.github/workflows/deploy.yml`) — on CI success for **`v*` tags only**: the
  `deploy-pages` job force-pushes the artifact to `gh-pages` (GitHub Pages — the public site at
  <https://mathewmusango.github.io/my-portfolio/>, committed as `mathewmusango`), and the
  `deploy-s3` job syncs it to the **prod S3 bucket** (`<project>-prod-site`) + CloudFront
  invalidation (OIDC `PROD_DEPLOY_ROLE_ARN`).
- **Release** (`.github/workflows/release.yml`) — on `v*` tags (or manual dispatch): builds,
  packages `site.zip`, generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt`,
  and creates/refreshes a GitHub Release with notes from `CHANGELOG.md`.

Build and release workflows use only the auto-scoped `GITHUB_TOKEN`. Deploys and Terraform
assume AWS roles via **OIDC** (no long-lived keys) using repo secrets: `STAGING/PROD_TERRAFORM_ROLE_ARN`,
`STAGING/PROD_DEPLOY_ROLE_ARN`, `PROJECT`, `AWS_REGION`, `PROD_ALLOWED_ORIGIN`.

## Infrastructure as Code (Terraform)

Real AWS infrastructure, defined with **Terraform** — a site-first stack:

- **Site (live)** — private S3 bucket + CloudFront (OAC, HTTP/2+3, localized error pages,
  serving at `/`). The staging and prod sites deploy here via the workflows above; buckets are
  **never public** (origin access control only).
- **Metrics (gated, `enable_metrics=false` until the metrics phase)** — API Gateway → Lambda →
  DynamoDB behind a geo-enabled CloudFront edge. **Free-Tier by default**: least-privilege IAM,
  an edge origin-gate (403 for non-site origins, HTTPS only) and multi-origin CORS (auto-includes
  the site's own CloudFront domain). WAF + a private VPC are opt-in behind `enable_waf`/`enable_vpc`.
- **Per-environment roles split by job**: `-terraform` (stack plan/apply) and `-deploy` (S3
  content sync + invalidation only — least privilege for the role that runs most).
- Applied via GitHub Actions using OIDC — the environment comes from the trigger (main →
  staging, `v*` tags → prod). **Staging applies automatically on `main`; prod plans only — its
  apply stays manual.** No state or secrets are ever committed; state lives in per-env private
  S3 backends with DynamoDB locking.

## Security

- See [SECURITY.md](SECURITY.md) for the vulnerability reporting policy.
- **Dependabot** keeps `requirements.txt` (weekly) and GitHub Actions (monthly) up to date.
- Every release ships an SBOM, and `pip-audit` runs on every CI build.

## License

[MIT](LICENSE)

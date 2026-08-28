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

Workflow files follow `{task}-{env|language|resource}` naming (e.g. `deploy-staging.yml`,
`checks-python.yml`, `invalidate-cloudfront.yml`); task-only names for single-purpose files
(`ci.yml`, `release.yml`).

- **CI** (`.github/workflows/ci.yml`) — on every push/PR to `main` **and `v*` tags**: shared
  build action (pip cache, `mkdocs build --strict`, `pip-audit` dependency audit, internal link
  check, CSS sanity check) with the production `site_url`; uploads the built `site/` as an
  artifact (7-day retention).
- **Terraform checks** (`.github/workflows/checks-terraform.yml`) — static checks on the
  terraform code (once per `main` push when `terraform/**` changes, or manual dispatch):
  `terraform fmt -check`, `validate`
  (all three roots: `terraform/`, `terraform/ci/`, `modules/metrics`), TFLint, and a Checkov
  security scan (informational for now). No AWS credentials — this complements (does not
  replace) the `terraform.yml` plan/apply pipeline.
- **Per-surface checks** (`.github/workflows/{checks-shell,checks-python,checks-yml}.yml`) — one workflow
  per language, each running once per `main` push (or manual dispatch) when the files it checks
  change: `shellcheck` on `scripts/*.sh`, `ruff` on `terraform/lambda/**` + `scripts/*.py`,
  and `actionlint` on `.github/workflows/**`. Grouped by surface (Terraform stays its own
  file) so a change to one language only runs that language's checks — a checks file's own
  change does not re-trigger it (workflow files are linted by `checks-yml`).
- **Deploy staging** (`.github/workflows/deploy-staging.yml`) — on CI success for `main` pushes:
  syncs the artifact to the **staging S3 bucket** (`<project>-staging-site`) + CloudFront
  invalidation (OIDC `STAGING_DEPLOY_ROLE_ARN`).
- **Deploy prod** (`.github/workflows/deploy-prod.yml`) — on CI success for **`v*` tags only**: the
  `deploy-pages` job force-pushes the artifact to `gh-pages` (GitHub Pages — the public site at
  <https://mathewmusango.github.io/my-portfolio/>, committed as `mathewmusango`), and the
  `deploy-s3` job syncs it to the **prod S3 bucket** (`<project>-prod-site`) + CloudFront
  invalidation (OIDC `PROD_DEPLOY_ROLE_ARN`).
- **CloudFront invalidation** — the deploy jobs run their own **inline** `/*` invalidation
  right after the sync (atomic with the deploy: lookup by the `<project>-<env>-site` comment
  convention, skip when the distro is absent). Manual purges (out-of-band content changes) go
  through `invalidate-cloudfront.yml` (`workflow_dispatch`) or locally via
  `scripts/invalidate-cloudfront.sh <staging|prod> [paths]` — the reference implementation if
  the inline steps are ever centralized:

  ```sh
  # Reference — the script used by the manual paths (also the centralized pattern)
  scripts/invalidate-cloudfront.sh staging            # full invalidation (/*)
  scripts/invalidate-cloudfront.sh prod "/about/ /metrics/"   # specific paths
  ```
- **Release** (`.github/workflows/release.yml`) — on `v*` tags (or manual dispatch): builds,
  packages `site.zip`, generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt`,
  and creates/refreshes a GitHub Release with notes from `CHANGELOG.md`.

Build and release workflows use only the auto-scoped `GITHUB_TOKEN`. Deploys and Terraform
assume AWS roles via **OIDC** (no long-lived keys) using repo secrets: `STAGING/PROD_TERRAFORM_ROLE_ARN`,
`STAGING/PROD_DEPLOY_ROLE_ARN`, `PROJECT`, `AWS_REGION`, `STAGING/PROD_ALLOWED_ORIGIN`,
`STAGING/PROD_METRICS_ENDPOINT`. No deployment value is hardcoded — terraform variables
(`project`, `environment`, `aws_region`, `allowed_origin`, `tags`) are injected at runtime from
secrets (CI) or `local.tfvars` (local dev).

## Infrastructure as Code (Terraform)

Real AWS infrastructure, defined with **Terraform** — a site + metrics stack:

- **Site (live)** — private S3 bucket + CloudFront (OAC, HTTP/2+3, localized error pages,
  serving at `/`). The staging and prod sites deploy here via the workflows above; buckets are
  **never public** (origin access control only).
- **Metrics (live — both environments)** — API Gateway → Lambda → DynamoDB behind a
  geo-enabled CloudFront edge (visitor country/city from CloudFront headers — no IPs are
  stored, raw events expire after 90 days via DynamoDB TTL). **Free-Tier by default**: least-
  privilege IAM, an edge origin-gate (403 for non-site origins, HTTPS only) and multi-origin
  CORS (auto-includes the site's own CloudFront domain). WAF + a private VPC are opt-in behind
  `enable_waf`/`enable_vpc`.
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

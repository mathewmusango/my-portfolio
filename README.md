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

- **CI** (`.github/workflows/ci.yml`) — on every push/PR to `main`: shared build action
  (pip cache, `mkdocs build --strict`, `pip-audit` dependency audit, internal link check, CSS
  sanity check) with the production `site_url`; uploads the built `site/` as an artifact
  (7-day retention).
- **Deploy** (`.github/workflows/deploy.yml`) — separate stage triggered when CI **completes
  successfully** on `main` (`workflow_run`): downloads the CI artifact and force-pushes the
  static output to the `gh-pages` branch, which GitHub Pages serves at
  <https://mathewmusango.github.io/my-portfolio/>. Deploy commits are authored as `mathewmusango`.
- **Release** (`.github/workflows/release.yml`) — on `v*` tags (or manual dispatch): builds,
  packages `site.zip`, generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt`,
  and creates/refreshes a GitHub Release with notes from `CHANGELOG.md`.

Build, deploy, and release workflows use only the auto-scoped `GITHUB_TOKEN`. The Terraform
workflow additionally assumes an AWS role via **OIDC** (no long-lived keys) using repo secrets
(`AWS_ROLE_ARN`, `AWS_REGION`, `METRICS_ENDPOINT`).

## Infrastructure as Code (Terraform)

The site's visitor-analytics backend is real AWS infrastructure, defined with **Terraform**:

- **CloudFront → API Gateway (HTTP API) → Lambda → DynamoDB** — **Free-Tier by
  default**: least-privilege IAM (separate writer/reader roles) and a Lambda
  origin gate (403 for non-site requests). WAF + a private VPC are opt-in
  (~$14/mo combined) behind `enable_waf`/`enable_vpc`.
- The Terraform definitions live in this repository (`terraform/`), applied via
  GitHub Actions using OIDC — the environment is chosen by the trigger (main →
  staging, `v*` tags → prod); plans run automatically, **apply is manual only**.
  No state or secrets are ever committed; state lives in a private S3 backend
  with DynamoDB locking.

## Security

- See [SECURITY.md](SECURITY.md) for the vulnerability reporting policy.
- **Dependabot** keeps `requirements.txt` (weekly) and GitHub Actions (monthly) up to date.
- Every release ships an SBOM, and `pip-audit` runs on every CI build.

## License

[MIT](LICENSE)

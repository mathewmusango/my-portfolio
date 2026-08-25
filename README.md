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

This repo is the **production mirror** — it exists so GitHub Actions can build and deploy the
site. Local development (live-reload dev server with podman, `compose.yaml`) happens in the
private source repo, which also holds the promotion tooling (`promote.sh`) and the full
DevOps/SRE documentation (`DEVOPS.md`).

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

No stored secrets are required — workflows use the auto-scoped `GITHUB_TOKEN`.

## Infrastructure as Code (Terraform)

The site's visitor-analytics backend is real AWS infrastructure, defined with **Terraform**:

- **CloudFront → API Gateway (HTTP API) → Lambda → DynamoDB**, with a private VPC
  for the functions (no internet path — only VPC endpoints), a WAF that allows
  only the site's origin, and least-privilege IAM (separate writer/reader roles).
- The Terraform definitions live in this repository (`terraform/`), applied via
  GitHub Actions using OIDC — planned on every change, applied on manual
  dispatch only. No state or secrets are ever committed; state lives in a
  private S3 backend with DynamoDB locking.

## Security

- See [SECURITY.md](SECURITY.md) for the vulnerability reporting policy.
- **Dependabot** keeps `requirements.txt` (weekly) and GitHub Actions (monthly) up to date.
- Every release ships an SBOM, and `pip-audit` runs on every CI build.

## License

[MIT](LICENSE)

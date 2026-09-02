# My Portfolio

[![Email](https://img.shields.io/badge/email-join-blue.svg)](mailto:musangomathew@gmail.com)
[![Web](https://img.shields.io/badge/web-view-green.svg)](https://mathewmusango.github.io/my-portfolio/)
[![My Portfolio](https://img.shields.io/github/v/release/mathewmusango/my-portfolio)](https://github.com/mathewmusango/my-portfolio/releases)
[![License](https://img.shields.io/github/license/mathewmusango/my-portfolio)](https://github.com/mathewmusango/my-portfolio/blob/main/LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/mathewmusango/my-portfolio/ci.yml?branch=main)](https://github.com/mathewmusango/my-portfolio/actions)

Personal portfolio site for **Mathew Musango Peter** — Platform Engineering Manager.
Built with **MkDocs + Material for MkDocs**, dark-teal theme.

> **Personal project developed in the open** — the OSS-style process (PRs, checks,
> releases) is a deliberate practice, not a community project.

Live: <https://mathewmusango.github.io/my-portfolio/>

> Code is MIT-licensed (see [LICENSE](LICENSE)). All personal content — text, resume,
> certifications, and images — © Mathew Musango Peter, all rights reserved.

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
`scripts/serve.py`, which also exposes a `/health` endpoint). The dev server serves **HTTPS**
via a local mkcert CA (certs in `certs/`, gitignored) — visit `https://portfolio.mathewmusango.test:8000`
(needs `127.0.0.1 portfolio.mathewmusango.test` in `/etc/hosts`); regenerated per machine with
`mkcert portfolio.mathewmusango.test localhost 127.0.0.1`. Commits to `main` are built,
checked, and deployed automatically by GitHub Actions (below).

## CI / CD

Workflow files follow `{task}-{env|language|resource}` naming (e.g. `deploy-staging.yml`,
`checks-python.yml`, `invalidate-cloudfront.yml`); task-only names for single-purpose files
(`ci.yml`, `release.yml`). Display `name:` fields use `{Category}: {Task}` (quoted — a colon+space
is invalid unquoted YAML): `Build` · `Checks: {language}` · `Deploy: {env} {target}` · `Infra: {task}` —
and `workflow_run` triggers match display names (the deploy workflows watch `Build`).

- **Build** (`.github/workflows/ci.yml`) — on every push/PR to `main` **and `v*` tags**: shared
  build action (pip cache, `mkdocs build --strict`, `pip-audit` dependency audit, internal link
  check, CSS sanity check) with the per-environment `site_url` (tags → prod, main → staging); uploads the built `site/` as an
  artifact (7-day retention).
- **Terraform checks** (`.github/workflows/checks-terraform.yml`) — static checks on the
  terraform code (on pull requests, or manual dispatch — the stage checks skip, green, when
  `terraform/**` isn't touched):
  `terraform fmt -check`, `validate`
  (all three roots: `terraform/`, `terraform/ci/`, `modules/metrics`), TFLint, and a Checkov
  security scan (informational for now). No AWS credentials — this complements (does not
  replace) the `terraform.yml` plan/apply pipeline.
- **Per-surface checks** (`.github/workflows/checks-{shell,python,js,terraform,yml}.yml`) —
  one workflow per surface, running on pull requests (or manual dispatch) with a job-level
  relevance gate (`dorny/paths-filter`): when the PR touches none of the surface's files the
  check **skips and reports success** — GitHub treats skipped jobs as success — so requiring all
  checks never blocks unrelated PRs. Covers: `shellcheck` on `scripts/*.sh` + `.githooks/**`,
  `ruff` on `**/*.py`, `node --check` on `**/*.js` (project + vendored), actionlint + YAML parse
  on `**/*.yml`/`**/*.yaml` (workflow-file edits self-validate), and the terraform stage checks
  on `terraform/**`.
- **Local checks** (`check-compose.yaml`) — the same checks run locally as stage 1, one compose
  service per check (`podman-compose -f check-compose.yaml run --rm <shell|python|yaml|yaml-syntax|js>`),
  mirroring the GitHub workflows exactly (same commands + tool images). **Changed-files-only:**
  `scripts/check_changed.sh` (pre-commit friendly; install with `git config core.hooksPath .githooks`).
  The GitHub workflows remain the authoritative gate (stage 2).
- **Deploy staging** (`.github/workflows/deploy-staging.yml`) — on CI success for `main` pushes:
  syncs the artifact to the **staging S3 bucket** (`<project>-staging-site`) with the S3-only
  deploy role, then invalidates CloudFront with the edge-invalidate role (least privilege —
  `STAGING_DEPLOY_ROLE_ARN` + `STAGING_INVALIDATE_ROLE_ARN`).
- **Deploy prod pages** (`.github/workflows/deploy-prod-pages.yml`) — on CI success for **`v*` tags
  only**: publishes the artifact to **GitHub Pages** (the public site at
  <https://mathewmusango.github.io/my-portfolio/>) via the official Pages actions
  (`configure-pages` → `upload-pages-artifact` → `deploy-pages`) — **least privilege**: only
  `pages: write` + `id-token: write`, no `contents: write`; the **`prod`** environment. Requires
  the repo Pages setting: source = **GitHub Actions** (flip right before the next `v*` deploy).
- **Deploy prod s3** (`.github/workflows/deploy-prod-s3.yml`) — on CI success for **`v*` tags only**:
  syncs the artifact to the **prod S3 bucket** (`<project>-prod-site`) + CloudFront
  invalidation (OIDC `PROD_DEPLOY_ROLE_ARN` + `PROD_INVALIDATE_ROLE_ARN`) — the **`pre-prod`**
  environment (AWS mirror of the canonical site).
- **Environments:** the deploy workflows declare per-environment environments — `staging` (auto,
  ungated), `pre-prod` (AWS mirror), `prod` (GitHub Pages). Required reviewers are configured per
  environment in Settings (recommended: required reviewer only on `prod`, so the mirror lands
  first for verification and the canonical site follows on approval). Secrets stay repo-level for
  now (`STAGING_*` / `PROD_*` prefixes); env-scoped secrets are a future idea.
- **Toggle env** (`.github/workflows/toggle-env.yml` + `scripts/toggle_cloudfront.sh`) — manual
  dispatch: **disable/enable STAGING CloudFront distributions** (component `site`|`metrics`,
  action disable|enable) by flipping `Enabled` in place via the AWS CLI —
  the invalidation-style toggle: no terraform apply runs, nothing can be deleted. **Staging only by
  design** — prod has no toggle role (an accidental disable on the prod metrics edge would stop
  collection). Uses the staging edge-toggle role (`STAGING_TOGGLE_ROLE_ARN`). Caveat: the flag
  lives outside terraform state, so the next apply restores it to enabled.
- **CloudFront invalidation** — the deploy jobs run their own **inline** `/*` invalidation
  right after the sync (atomic with the deploy: lookup by the `<project>-<env>-site` comment
  convention, skip when the distro is absent). Manual purges (out-of-band content changes) go
  through `invalidate-cloudfront.yml` (`workflow_dispatch`) or locally via
  `scripts/invalidate_cloudfront.sh <staging|prod> [paths]` — the reference implementation if
  the inline steps are ever centralized:

  ```sh
  # Reference — the script used by the manual paths (also the centralized pattern)
  scripts/invalidate_cloudfront.sh staging            # full invalidation (/*)
  scripts/invalidate_cloudfront.sh prod "/about/ /metrics/"   # specific paths
  ```
- **Release** (`.github/workflows/release.yml`) — on `v*` tags (or manual dispatch): builds,
  packages `site.zip`, generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt`,
  and creates/refreshes a GitHub Release with notes from `CHANGELOG.md`.

Build and release workflows use only the auto-scoped `GITHUB_TOKEN`. Deploys and Terraform
assume AWS roles via **OIDC** (no long-lived keys) using repo secrets: `STAGING/PROD_TERRAFORM_ROLE_ARN`,
`STAGING/PROD_DEPLOY_ROLE_ARN`, `STAGING/PROD_INVALIDATE_ROLE_ARN`, `STAGING_TOGGLE_ROLE_ARN`,
`PROJECT`, `AWS_REGION`, `STAGING/PROD_ALLOWED_ORIGIN`,
`STAGING/PROD_METRICS_ENDPOINT`, `STAGING/PROD_SITE_URL`. No deployment value is hardcoded — terraform variables
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
- **Per-environment roles split by job (least privilege)**: `-terraform` (stack plan/apply,
  tag-locked for prod) · `-deploy` (S3 content sync only) · `-invalidate` (edge purge) ·
  `-toggle` (edge `Enabled` flip, staging only) — each workflow assumes only the role its step needs.
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

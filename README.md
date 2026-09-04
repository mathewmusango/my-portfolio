# My Portfolio

[![Email](https://img.shields.io/badge/email-join-blue.svg)](mailto:musangomathew@gmail.com)
[![Web](https://img.shields.io/badge/web-view-green.svg)](https://mathewmusango.github.io/my-portfolio/)
[![My Portfolio](https://img.shields.io/github/v/release/mathewmusango/my-portfolio)](https://github.com/mathewmusango/my-portfolio/releases)
[![License](https://img.shields.io/github/license/mathewmusango/my-portfolio)](https://github.com/mathewmusango/my-portfolio/blob/main/LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/mathewmusango/my-portfolio/ci.yml?branch=main)](https://github.com/mathewmusango/my-portfolio/actions)

![Site preview](docs/assets/site-preview.png)
*The live site — [mathewmusango.github.io/my-portfolio](https://mathewmusango.github.io/my-portfolio/)*

> **Personal project developed in the open** — the OSS-style process (PRs, checks,
> releases) is a deliberate practice, not a community project.

Personal portfolio site for **Mathew Musango Peter** (Platform Engineering Manager), built with
MkDocs + Material and shipped to production standards: gated multi-environment releases,
least-privilege OIDC roles, and privacy-first visitor analytics (no IPs stored). The personal
side — profile, experience, certifications, resume — is on the site; this repository is the
engineering behind it ([Architecture](#architecture)).

> Code is MIT-licensed (see [LICENSE](LICENSE)). All personal content — text, resume,
> certifications, and images — © Mathew Musango Peter, all rights reserved.

## Tech Stack

| Layer      | Tooling                                                               |
| ---------- | --------------------------------------------------------------------- |
| Site       | [MkDocs](https://www.mkdocs.org/) 1.6.1 + [Material](https://squidfunk.github.io/mkdocs-material/) 9.7.7 |
| Theme      | Material — dark slate (default), light toggle, teal `#00897b` accent   |
| Plugins    | Search (suggest/highlight), git revision dates + contributors, minify |
| PDF viewer | pdf.js (self-hosted) with clickable, new-tab links overlays            |
| Analytics  | Privacy-first visitor metrics — CloudFront geo headers → API Gateway → Lambda → DynamoDB (no IPs stored, 90-day TTL) |

## Architecture

The project is a three-part platform — content delivery, visitor metrics, and the Terraform
behind both. Each part ships through real CI/CD; the deep detail lives in
[CI / CD](#ci--cd), [Terraform](#infrastructure-as-code-terraform) and
[`terraform/README.md`](terraform/README.md).

### Site — content delivery

```mermaid
flowchart LR
    subgraph Local[dev]
        DEV[podman-compose · serve.py<br/>HTTPS via mkcert]
    end
    subgraph GHA[GitHub Actions]
        B[ci.yml — build + checks] -->|main| D1[deploy-staging-s3]
        B -->|v* tag| D2[deploy-pre-prod-s3]
        B -->|v* tag| D3[deploy-prod-pages]
    end
    D1 --> STG[staging — S3 + CloudFront · OAC]
    D2 --> PRE[pre-prod — S3 + CloudFront · OAC]
    D3 --> PRD[prod — GitHub Pages]
```

**Prod is gated**: the Pages deploy runs behind a required reviewer in the `prod` GitHub
environment — `pre-prod` (the AWS mirror) lands first, then Pages ships on approval. Two
delivery planes, each with its own gate: **content** — `main` → staging · `v*` → pre-prod →
gated Pages; **infrastructure** — `main` → staging auto-applies · `v*` → prod plan-only.

### Metrics — visitor analytics

```mermaid
flowchart LR
    V[site visitor] -->|POST /event| CF[CloudFront<br/>geo headers]
    CF --> GW[API Gateway]
    GW -->|POST /event| W[Lambda — writer]
    GW -->|GET /summary · /views · /health| R[Lambda — reader]
    W -->|PutItem| DB[(DynamoDB<br/>TTL 90 days)]
    R -->|Scan · Query| DB
```

**staging** runs its own stack; **pre-prod + prod** share one; **dev** runs Ministack (no edge).
Writer and reader lambdas each have their own least-privilege role. Privacy-first: geo only — no
IPs stored, raw events expire — CloudFront supplies the geo headers, so no IP address ever
reaches the Lambda ([Why CloudFront?](terraform/README.md#why-cloudfront)).

### Terraform — the control plane

```mermaid
flowchart TB
    BOOT[terraform/ci — bootstrap<br/>manual · run as an AWS user] --> STATE[(state backends<br/>S3 + DynamoDB lock<br/>staging · prod · local dev)]
    BOOT --> ROLES[OIDC roles — least privilege, one per job<br/>-terraform · -deploy · -invalidate · -toggle]
    WORK[GitHub Actions workflows] -->|assume role| ROLES
    ROLES -->|plan · apply · sync| STACKS[site + metrics stacks<br/>staging · prod]
```

`terraform/ci` creates the per-environment state backends and the OIDC roles GitHub Actions
assumes to build and run the stacks. **Bootstrap is the one out-of-band step** — an AWS user,
outside GitHub Actions, creates them with its own IAM permissions; no workflow ever uses keys.

## Getting Started

**Prerequisites**

- [Podman](https://podman.io/) + [podman-compose](https://github.com/containers/podman-compose) — the
  dev server and all tooling run in containers; **no local Python/venv needed**.
- [mkcert](https://github.com/FiloSottile/mkcert) — local HTTPS (once per machine).

**One-time local setup** — trust the local CA, generate the site cert into `certs/` (gitignored),
and map the dev host:

```sh
mkcert -install                                  # trust the local root CA
mkdir -p certs
mkcert -cert-file certs/portfolio.pem -key-file certs/portfolio-key.pem \
  portfolio.mathewmusango.test localhost 127.0.0.1
echo "127.0.0.1 portfolio.mathewmusango.test" | sudo tee -a /etc/hosts
```

**Run**

```sh
git clone https://github.com/mathewmusango/my-portfolio.git
cd my-portfolio
podman-compose -f compose.yaml up -d
```

Open <https://portfolio.mathewmusango.test:8000> — the dev server (live-reload) also exposes a
`/health` endpoint. See [Development](#development) for how the container maps to CI/CD.

## Development

The repository is the **single source of truth** — the same `docs/` tree builds the local site and
the deployed one. Setup and first run are in [Getting Started](#getting-started); the details:

- **Live-reload dev server** — `compose.yaml` (podman, container `my-portfolio`) runs
  `scripts/serve.py`, an HTTPS-capable MkDocs dev server that also exposes `/health` (the
  container healthcheck curls it).
- **HTTPS** — TLS via the local [mkcert](https://github.com/FiloSottile/mkcert) CA (certs in
  `certs/`, gitignored); `serve.py` falls back to plain HTTP with a warning if the certs are
  missing. Setup commands are in [Getting Started](#getting-started).
- Commits to `main` are built, checked, and deployed automatically by GitHub Actions — see
  [CI / CD](#ci--cd).

## CI / CD

How a change ships (the [Architecture](#architecture) site diagram shows the targets):

```mermaid
flowchart LR
    M[push / PR to main] --> C{required checks<br/>per-surface · skip-model}
    V[v* tag<br/>ruleset-gated] --> C
    C -->|pass| B[Build — ci.yml]
    V --> B
    B --> A[site artifact]
    A -->|workflow_run · main| S[deploy → staging env]
    A -->|workflow_run · v*| P[deploy → pre-prod → gated prod]
    V --> R[release — tag + SBOM]
    T[tf change] --> TP[terraform plan] -->|manual apply| AP[apply]
    X[workflow_dispatch] --> TG[toggle-env] & INV[invalidate]
```

Each of the four phases below is documented in [`.github/workflows/README.md`](.github/workflows/README.md)
(the implementation reference — triggers, roles, secrets) and
[`CONTRIBUTING.md`](CONTRIBUTING.md) (the required-checks table):

- **Build** (`ci.yml`) — strict `mkdocs build` + audits (pip-audit, link check) on every push/PR
  to `main` and `v*` tags; uploads the built `site/` as an artifact.
- **Checks** — one workflow per surface (`checks-{shell,python,js,terraform,yml}.yml`), gated on
  PRs by relevance: untouched surfaces **skip and report success**, so the required checks never
  block unrelated PRs. The same checks run locally (`scripts/check_local.sh` — changed-files by
  default, `--full` for whole-repo, mirroring the workflows exactly).
- **Deploy** — `workflow_run` on Build success: `main` → **staging** (S3 + CloudFront), `v*` tags
  → **pre-prod** (AWS mirror) → gated **prod** (GitHub Pages). Staging **skips** when the
  artifact is byte-identical to the last deploy (content-hash marker); prod runs in the `prod`
  environment behind a required reviewer.
- **Release & infra** — `v*` tags build a GitHub Release with a CycloneDX SBOM; `terraform.yml`
  plans on `terraform/**` changes (apply stays manual); `toggle-env` and `invalidate-cloudfront`
  are manual operational extras.

## Infrastructure as Code (Terraform)

Real AWS infrastructure, defined with **Terraform** — [`terraform/README.md`](terraform/README.md)
owes the full implementation (resources, event schema, security, local dev):

- **Site** — private S3 + CloudFront (OAC only — buckets are never public, localized error
  pages, serving at `/`), per environment; the deploys above sync the artifact into it.
- **Metrics** — privacy-first visitor analytics: geo comes from CloudFront headers (no IPs
  stored, 90-day TTL) via API Gateway → writer/reader lambdas → DynamoDB, origin-gated;
  WAF / private VPC are opt-in.
- **Control plane** — `terraform/ci` bootstraps the per-environment state backends (S3 +
  DynamoDB lock) and the per-job OIDC roles (see [Architecture](#architecture)). Staging
  applies automatically on `main`; prod applies stay manual. State/secrets are never committed.

## Security

- See [SECURITY.md](SECURITY.md) for the vulnerability reporting policy.
- **Dependabot** keeps `requirements.txt` (weekly) and GitHub Actions (monthly) up to date.
- Every release ships a CycloneDX SBOM, and `pip-audit` runs on every CI build.
- No long-lived keys anywhere — deploys and Terraform assume AWS roles via OIDC; buckets are
  never public (OAC only) and the metrics API is origin-gated (details in
  [`terraform/README.md`](terraform/README.md)).

## Documentation map

- [`README.md`](README.md) — this file: the system view (what the repo is, architecture, running it locally).
- [`terraform/README.md`](terraform/README.md) — infrastructure implementation (site + metrics stacks, event model, security, local AWS emulation).
- [`.github/workflows/README.md`](.github/workflows/README.md) — CI/CD implementation (every workflow, naming, roles, secrets, ops extras).
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — process: branching, required-checks table, issues/labels, releases.
- [`SECURITY.md`](SECURITY.md) — vulnerability reporting.
- [`CHANGELOG.md`](CHANGELOG.md) — release history.
- [`rulesets/`](rulesets/) — branch/tag rulesets: [`README`](rulesets/README.md) (what they do) · `main.json`/`tags.json` (as-code configs) · `main.md`/`tags.md` (verification records).

## License

[MIT](LICENSE)

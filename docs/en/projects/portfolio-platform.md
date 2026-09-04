---
icon: material/layers-triple
tags:
  - Platform Engineering
  - CI/CD
  - Terraform
  - AWS
  - GitHub Actions
  - MkDocs
  - DevSecOps
  - IaC
---

# The Platform Behind This Site

> Architecture visuals for this platform live in the [Site
> Structure](../../atlas/structure/) map and the repo
> [README diagrams](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" } —
> this page is the story, not the diagram dump.

This portfolio is the product — and this repository is the engineering platform
that builds, checks, deploys, and operates it. The site you are reading runs on
the same repo it documents: an MkDocs + Material product with a production-grade
delivery system around it, developed in the open as a deliberate demonstration
of how platform engineering is done on a small, real, public system.

- **The product (the site):** [mathewmusango.github.io/my-portfolio](https://mathewmusango.github.io/my-portfolio/){ target="_blank" rel="noopener" }
- **The platform (this repo):** [mathewmusango/my-portfolio](https://github.com/mathewmusango/my-portfolio){ target="_blank" rel="noopener" }
- **The code:** [MIT licensed](https://github.com/mathewmusango/my-portfolio/blob/main/LICENSE){ target="_blank" rel="noopener" } — personal content © the author.

## Why a platform for a portfolio?

A portfolio site is small; the process around it does not have to be. This
project deliberately applies the practices expected of production software — on
a public repository, at portfolio scale, where every trade-off is visible:

- **Everything ships like real software** — PRs, required checks, approvals, releases.
- **Every environment is a real environment** — dev, staging, pre-prod, prod.
- **Security is designed in** — no long-lived credentials, private storage, least privilege.
- **Privacy is an architectural property** — visitor analytics collect geo only, never IPs.
- **History is honest** — a [CHANGELOG](https://github.com/mathewmusango/my-portfolio/blob/main/CHANGELOG.md){ target="_blank" rel="noopener" }, tagged releases, and an [SBOM per release](https://github.com/mathewmusango/my-portfolio/releases){ target="_blank" rel="noopener" }.

The value is not the scale — it is the discipline. This page documents the
platform: its architecture, its delivery model, its governance, its security
posture, and the real incidents that shaped it.

## Architecture

The platform is three parts — **site delivery**, **visitor metrics**, and the
**Terraform control plane** behind both. (Interactive views: the [site-structure
diagram](../../atlas/structure/) maps the site; the repo
[README](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
carries the delivery, metrics, and control-plane diagrams.)

### Site — content delivery

Three deploy targets, one artifact. `main` deploys to **staging** (an S3 +
CloudFront pair in AWS, bucket private, served through OAC). `v*` tags deploy to
**pre-prod** — an AWS mirror of the canonical site — and then to **prod**:
GitHub Pages, behind a required reviewer in the `prod` environment.

### Metrics — visitor analytics

A deliberately small, fully serverless metrics stack. CloudFront supplies the
geo headers — so **no IP address ever reaches the Lambda**. The writer stores
country/city/region with a 90-day TTL; the reader serves the [Site
Metrics](../../metrics/) pages. Each Lambda has its own least-privilege role;
the API is public but origin-gated ([why CloudFront?](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md#why-cloudfront){ target="_blank" rel="noopener" }).

### Terraform — the control plane

`terraform/ci` creates the per-environment state backends and the OIDC roles
GitHub Actions assumes to build and run the stacks. **Bootstrap is the one
out-of-band step** — an AWS user, outside GitHub Actions, creates them with its
own IAM permissions; no workflow ever uses keys. Implementation detail:
[`terraform/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md){ target="_blank" rel="noopener" }.

## Delivery model {#delivery-model}

Two delivery planes, each with its own gate:

| Plane | Path | Gate |
|---|---|---|
| **Content** | `main` → staging · `v*` → pre-prod → gated Pages | required reviewer on `prod` |
| **Infrastructure** | `main` → staging auto-applies · `v*` → prod plan-only | manual `terraform apply` |

Deploys run on every successful CI build of the right ref
([#20](https://github.com/mathewmusango/my-portfolio/pull/20){ target="_blank" rel="noopener" } split
prod into Pages + S3 and moved to the official Pages actions). Staging **skips**
when the built artifact is byte-identical to the last deploy — a content-hash
marker scheme that keeps docs-only merges from churning the bucket
([#29](https://github.com/mathewmusango/my-portfolio/pull/29){ target="_blank" rel="noopener" },
[#31](https://github.com/mathewmusango/my-portfolio/pull/31){ target="_blank" rel="noopener" }).

## Development workflow

- The repository is the **single source of truth** — the same `docs/` tree builds locally and in CI.
- **Containers only** — `podman-compose up` runs the MkDocs dev server; no local Python/venv needed.
- **HTTPS locally** via a per-machine [mkcert](https://github.com/FiloSottile/mkcert){ target="_blank" rel="noopener" } root CA — parity with the TLS of the deployed site.
- The dev container also serves a `/health` endpoint used by its own healthcheck.
- Local checks mirror CI exactly (`check-compose.yaml` + `scripts/check_changed.sh`).

Getting-started steps: [the repo README](https://github.com/mathewmusango/my-portfolio#getting-started){ target="_blank" rel="noopener" }.

## CI / CD

A change ships through four phases — each documented in
[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }:

1. **Build** — strict `mkdocs build` (broken links, stale translations and CSS
   imbalance fail the build), `pip-audit`, and a built-site artifact on every
   push/PR to `main` and every `v*` tag.
2. **Checks** — one workflow per surface
   (`checks-{shell,python,js,terraform,yml}`). Each gates itself by changed
   paths ([skip-model, #17](https://github.com/mathewmusango/my-portfolio/pull/17){ target="_blank" rel="noopener" }):
   untouched surfaces **skip and report success**, so the ten required checks
   never block an unrelated PR.
3. **Deploy** — `workflow_run` on Build success: `main` → staging, `v*` →
   pre-prod + gated prod (see [Delivery model](#delivery-model)).
4. **Release & infra** — `v*` tags create a GitHub Release with a CycloneDX
   SBOM; Terraform plans on every infra change (apply stays manual);
   `toggle-env` / `invalidate-cloudfront` are manual operational extras.

Check names are the gate names — CI reports job names (`ci-build`,
`checks-python-ruff`, …) so branch protection and rulesets require exactly what
runs ([#12](https://github.com/mathewmusango/my-portfolio/pull/12){ target="_blank" rel="noopener" }).

## Governance

Rulesets-as-code protect the two refs that matter
([`rulesets/`](https://github.com/mathewmusango/my-portfolio/tree/main/rulesets){ target="_blank" rel="noopener" }):

| Ref | Protection |
|---|---|
| `main` | PR-only: 1 approval, squash/rebase, stale reviews dismissed, all 10 required checks, no force-push, **no bypass — owner included** |
| `v*` tags | Minted only by the maintainer; green `ci-build` required; immutable once created |

Enforcement is push-time and verified — rejection records sit beside the
configs in `rulesets/main.md` and `rulesets/tags.md`. PRs carry labels mapped to
a curated set (`ci` · `infra` · `security` · `governance` · `dependencies`), and
a second GitHub account reviews as a normal collaborator — the owner merges
nothing unapproved. Issue templates enforce a seven-part structure
([#15](https://github.com/mathewmusango/my-portfolio/pull/15){ target="_blank" rel="noopener" },
[#18](https://github.com/mathewmusango/my-portfolio/pull/18){ target="_blank" rel="noopener" }).

## Security

- **No long-lived keys** — deploys and Terraform assume AWS roles via OIDC
  ([#22](https://github.com/mathewmusango/my-portfolio/pull/22){ target="_blank" rel="noopener" }
  extended the trust for environment-bearing jobs).
- **Least privilege per job** — separate `-terraform` · `-deploy` · `-invalidate`
  · `-toggle` roles; the prod metrics edge has **no** toggle role by design.
- **Private storage** — S3 buckets are never public; CloudFront serves them through OAC only.
- **Origin-gated API** — the metrics endpoint is public but restricted to the
  configured site origin; WAF/VPC are opt-in (Free-Tier-first posture).
- **Dependency hygiene** — [Dependabot](https://github.com/mathewmusango/my-portfolio/security/dependabot){ target="_blank" rel="noopener" },
  `pip-audit` on every build, a CycloneDX SBOM on every release, Checkov in CI.
- Reporting policy: [SECURITY.md](https://github.com/mathewmusango/my-portfolio/blob/main/SECURITY.md){ target="_blank" rel="noopener" }.

## Real incidents, and the lessons they left

The platform has broken in production in instructive ways. Each incident is
documented in the
[CHANGELOG](https://github.com/mathewmusango/my-portfolio/blob/main/CHANGELOG.md){ target="_blank" rel="noopener" };

| Incident | Root cause | Fix |
|---|---|---|
| **Staging 403 on every object** | SSE-KMS is incompatible with CloudFront OAC (no `kms:Decrypt`) | Reverted to AES256 ([`aee25c6`](https://github.com/mathewmusango/my-portfolio/commit/aee25c6){ target="_blank" rel="noopener" }) |
| **Staging went stale on multi-commit batches** | Deploy gate diffed `HEAD~1..HEAD` only | Deploys now run on every successful CI build ([`1bf9bd9`](https://github.com/mathewmusango/my-portfolio/commit/1bf9bd9){ target="_blank" rel="noopener" }) |
| **Docs-only merges churned the bucket** | `s3 sync` always re-uploaded fresh extractions | Content-hash marker skip ([#29](https://github.com/mathewmusango/my-portfolio/pull/29){ target="_blank" rel="noopener" }, [#31](https://github.com/mathewmusango/my-portfolio/pull/31){ target="_blank" rel="noopener" }) |
| **"Expected — waiting" checks** | Required check names that no run had reported yet | Registered names first; skip-model for path-relevant gating ([#12](https://github.com/mathewmusango/my-portfolio/pull/12){ target="_blank" rel="noopener" }, [#17](https://github.com/mathewmusango/my-portfolio/pull/17){ target="_blank" rel="noopener" }) |

The pattern in each: a real failure, a fix at the root, and the runbook update
that keeps it from recurring — the same loop this site documents as the
[release timeline](../../atlas/releases/).

## How to explore

- **[Repo README](https://github.com/mathewmusango/my-portfolio/blob/main/README.md){ target="_blank" rel="noopener" }** — the system view: architecture, running it locally.
- **[`terraform/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md){ target="_blank" rel="noopener" }** — infrastructure implementation and rationale.
- **[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }** — every workflow, role, and operational extra.
- **[`CONTRIBUTING.md`](https://github.com/mathewmusango/my-portfolio/blob/main/CONTRIBUTING.md){ target="_blank" rel="noopener" }** — how a change becomes a merge.
- **[Site Atlas](../../atlas/)** — release timeline, tags, and the site structure map.
- **[GitHub Actions](https://github.com/mathewmusango/my-portfolio/actions){ target="_blank" rel="noopener" }** — the pipeline live.

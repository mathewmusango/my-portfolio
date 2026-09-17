# Workflows — CI/CD Implementation Reference

Every workflow in `.github/workflows/` — what it does, how it's triggered, which roles and
secrets it uses, and the gotchas. The **system view** (how a change ships) lives in the root
[`README.md`](../README.md#ci--cd); this file is the implementation detail. The **process**
(branching, the required-checks table, issues/labels, releases) lives in
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Naming conventions

- **File names** — `{task}-{env|language|resource}` (`invalidate-cloudfront.yml`); task-only
  names for single-purpose files (`ci.yml`, `checks.yml`, `deploy.yml`, `release.yml`).
- **Display names** — quoted `{Category}: {Task}` (a colon+space is invalid unquoted YAML):
  `ci` · `Checks: {language}` · `Deploy: {env} {target}` · `Infra: {task}`.
- **`workflow_run` matches display names** — the deploy workflows watch `ci`; renaming a
  display name requires updating every `workflow_run` reference.

## ci — `ci.yml` (`ci`)

- **Triggers:** push to `main` and `v*` tags; pull requests to `main`.
- Runs the shared [`.github/actions/build-site`](../.github/actions/build-site) action: pip cache,
  `mkdocs build --strict`, translation-parity check, `pip-audit` dependency audit, internal link
  check, CSS sanity check — with the per-environment `site_url` (tags → prod, main → staging)
  and `METRICS_ENDPOINT`.
- Uploads the built `site/` as an artifact (7-day retention).

## Checks — `checks.yml`

- **One workflow, a shared library.** `checks.yml` is the **only** check workflow in this repo
  (it replaced the five per-surface `checks-*.yml` files). It holds no check logic itself —
  each job calls a reusable workflow hosted in the shared library
  `mathewmusango/my-workflows` pinned to a **commit SHA**; the reusable paths below are
  relative to
  `mathewmusango/my-workflows/.github/workflows/`.
- **Triggers:** pull requests to `main` + manual dispatch.
- **Self-gating reusables:** each reusable runs its own `detect` job and gates on changed
  files — a surface whose files are untouched **skips and reports success**, so requiring every
  check never blocks an unrelated PR.

| Caller job | Reusable workflow (`@v2`) | Reported check name |
| --- | --- | --- |
| `js` | `checks-js.yml` | `js / syntax` |
| `python` | `checks-python.yml` | `python / ruff` |
| `shell` | `checks-shell.yml` | `shell / shellcheck` |
| `terraform` | `checks-terraform.yml` | `terraform / fmt` · `terraform / validate` · `terraform / lint` · `terraform / security` |
| `yaml` | `checks-yaml.yml` | `yaml / syntax` · `yaml / actionlint` |
| `secrets` | `security-secrets.yml` | `secrets / gitleaks` |
| `deps` | `security-deps.yml` | `deps / dependency-review` — PRs only |

- **Surfaces:** `shellcheck` on every `*.sh` (repo-wide, excluding `site/`) + `.githooks/**` ·
  `ruff` on `**/*.py` · `node --check` on `**/*.js` (project + vendored) · actionlint + YAML
  parse on `**/*.yml`/`**/*.yaml` (workflow-file edits self-validate) · terraform stages on
  `terraform/**` + `.tflint.hcl` (`fmt -check`, `validate` on all three roots, TFLint, Checkov —
  informational, no AWS credentials) · `gitleaks` secret scan · `dependency-review` on
  dependency changes.
- **Required checks are the reported check names** — GitHub composes them as
  `<caller job key> / <leaf job name>` across the reusable boundary, so these (not the old
  `checks-*` names) are what branch protection and the `main` ruleset require — see the table
  in `CONTRIBUTING.md`.
- **Local parity:** `check-compose.yaml` mirrors the workflows exactly (one service per check,
  identical commands + tool images). `scripts/check_local.sh` is the one-entry driver — default
  runs every surface whose files changed (diff-gated, mirroring the CI skip-model); `--full` runs
  all surfaces on the whole repo. `scripts/check_changed.sh` is the pre-commit fast path
  (changed-files only: `git config core.hooksPath .githooks`). The GitHub workflows remain the
  authoritative gate.

## Deploy — `workflow_run` on ci success

One workflow — `deploy.yml` — carries all three targets, and holds only the trigger, the gate, the
permissions and one `uses:` per job. The logic lives in two composite actions beside it:
[`.github/actions/deploy-s3`](../actions/deploy-s3/action.yml) — download the artifact, assume
the **deploy role** (OIDC), `aws s3 sync` to the bucket root, then assume the **invalidate role**
for an inline `/*` invalidation (lookup by the `<project>-<env>-site` comment convention; skip
when the distro is absent) — and
[`.github/actions/deploy-pages`](../actions/deploy-pages/action.yml) — configure → upload →
deploy, never touching AWS. One S3 action serves both environments; `hash_skip` turns on the
staging content-hash skip. Each job gates itself with a job-level `if:` on the triggering ref;
never a workflow-level gate (a caller-level gate is what changed the reported check name for the
shared checks in `checks.yml`).

- **Why leaf actions here rather than reusable workflows in the library:** a job that calls a
  reusable workflow may carry only `name`/`uses`/`with`/`secrets`/`needs`/`if`/`permissions` —
  **`environment:` is rejected** — so the reviewer gate could not stay in the consumer, and a
  gate hosted in another repo could fail open (a prod deploy with no review and no error). A
  composite keeps the job, its gate and its permissions here, with the logic in one place.
  Constraint to remember: a composite **cannot read `secrets`**, so every sensitive value
  arrives through `with:` — the artifact token is `github.token`, which composites can read.

| Job | Runs on | Environment | Target | Gate |
| --- | --- | --- | --- | --- |
| `deploy-staging` | ci success on `main` | `staging` (auto, ungated) | `<project>-staging-site` (S3 + CloudFront) | content-hash skip (below) |
| `deploy-prod-s3` | ci success on `v*` tags | `prod` (required reviewer) | `<project>-prod-site` (S3 + CloudFront) — the prod AWS plane | tag only + approval |
| `deploy-pages` | ci success on `v*` tags | `prod` (required reviewer) | GitHub Pages (canonical) | tag only + approval |

- **`environment:` is load-bearing, not decoration.** A job that declares one presents the OIDC
  sub `repo:OWNER/REPO:environment:<name>` instead of the ref form, and AWS STS accepts only the
  shapes listed in the deploy roles' trust (`scripts/bootstrap_aws.sh` — prod lists
  `ref:refs/heads/main`, `environment:pre-prod`, `environment:prod`). So `environment:prod` had to
  be added to that trust **before** the AWS prod job was gated; renaming the environment without
  updating the trust breaks every AWS assume. The env-form sub also carries no ref, so a tag-only
  job is enforced by its own `if:` gate, never by the trust — the reviewer is what restrains it.
- **Permissions are per job, not workflow-level** — least privilege: only `deploy-pages`
  carries `pages: write`.

- **Least privilege:** the Pages job uses the official Pages actions
  (`configure-pages` → `upload-pages-artifact` → `deploy-pages`) with `pages: write` +
  `id-token: write` and **no `contents: write`** (`contents: read` + `actions: read` cover the
  artifact download); a `concurrency: group: pages` guard serializes deploys. **Requires** the
  repo Pages setting: source = **GitHub Actions** (flip right before the next `v*` deploy).
- **Secrets** stay repo-level with per-environment prefixes (env-scoped secrets are a future idea).

### Content-hash skip (staging)

Deploys on `main` skip sync + invalidation when the artifact is **byte-identical** to the last
staging deploy. Marker: a zero-byte object keyed by a SHA-256 of the site content under
`.deploy-hash/<hash>`, existence-checked with `s3 ls` — the deploy role deliberately has **no
`s3:GetObject`**, so the marker is written (`s3api put-object`) and listed, never read. The sync
excludes `.deploy-hash/*` so the marker survives `--delete`.

- **Why content, not commits:** the old commit-diff gate (`HEAD~1..HEAD`) let multi-commit
  batches go stale; content comparison can't — a skip only happens when the exact bytes to sync
  are already live.
- **Gotcha:** `aws s3 sync` compares size + mtime — freshly extracted artifacts always
  re-upload; the hash skip is what prevents it.
- **Edge case:** git-revision-date embeds can change the hash at day boundaries — then it
  deploys as usual (never stale, best-effort).

## Release — `release.yml`

- **Triggers:** `v*` tags or manual dispatch. Packages `site.zip`, generates a CycloneDX SBOM
  (`sbom.cdx.json`) from `requirements.txt`, and creates/refreshes a GitHub Release with notes
  from `CHANGELOG.md`.
- Releases do **not** drive deploys (tags do) — they publish the SBOM, artifact, and notes.

## Infra — `terraform.yml` + operational extras

- **`terraform.yml`** — plans on any change to `terraform/**`: `main` → staging (auto-apply),
  `v*` tags → prod (plan only — apply stays manual via `workflow_dispatch`). Deep docs:
  [`terraform/README.md`](../terraform/README.md).
- **`toggle-env.yml`** + `scripts/toggle_cloudfront.sh` — manual dispatch: disable/enable
  **staging** CloudFront distributions (component `site`|`metrics` × action `disable`|`enable`)
  by flipping `Enabled` in place (no terraform apply, nothing deleted). **Staging only by
  design** — prod has no toggle role. Caveat: the flag lives outside terraform state, so the
  next apply restores `enabled=true`. Uses the staging edge-toggle role (per-env secret).
- **`invalidate-cloudfront.yml`** + `scripts/invalidate_cloudfront.sh <staging|prod> [paths]` —
  manual edge purges for out-of-band content changes (the reference implementation for the
  inline deploy invalidation):

  ```sh
  scripts/invalidate_cloudfront.sh staging            # full invalidation (/*)
  scripts/invalidate_cloudfront.sh prod "/about/ /metrics/"   # specific paths
  ```

## Auth model

```mermaid
flowchart LR
    subgraph GHA[GitHub Actions]
        BR[ci · checks · release] -->|auto-scoped GITHUB_TOKEN<br/>release elevates to contents: write| API[GitHub API]
        DT[Deploy · terraform.yml] -->|OIDC — no long-lived keys| AWS[AWS]
    end
    AWS --> JR[per-environment, per-job roles<br/>terraform · deploy · invalidate · toggle]
    JR --> RES[site + metrics stacks]
```

ci/checks/release talk to the GitHub API with the auto-scoped `GITHUB_TOKEN` (Release
elevates it to `contents: write` to create the Release). Deploys and Terraform assume **AWS
roles via OIDC** — one least-privilege role per job per environment; the only key-based step is
the out-of-band `terraform/ci` bootstrap, run as an AWS user.

The per-environment role ARNs and deployment values live as **repo secrets** (Settings → Secrets
and variables → Actions), referenced by name from the workflows. Names follow a fixed pattern
(`ENV` ∈ `STAGING` / `PROD`):

| Pattern | Purpose |
| --- | --- |
| `{ENV}_DEPLOY_ROLE_ARN` · `{ENV}_INVALIDATE_ROLE_ARN` | S3 sync + edge purge roles |
| `{ENV}_TERRAFORM_ROLE_ARN` | plan/apply role |
| `{ENV}_TOGGLE_ROLE_ARN` | edge on/off flip (staging only) |
| `PROJECT` · `AWS_REGION` | shared — bucket naming, region |
| `{ENV}_ALLOWED_ORIGIN` · `{ENV}_METRICS_ENDPOINT` · `{ENV}_SITE_URL` | per-env build/run values |

Terraform variables (`project`, `environment`, `aws_region`, `allowed_origin`, `tags`) are
injected from those secrets (CI) or `local.tfvars` (local dev) — nothing is hardcoded.

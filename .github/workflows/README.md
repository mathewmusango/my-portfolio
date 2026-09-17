# Workflows — CI/CD Implementation Reference

Every workflow in `.github/workflows/` — what it does, how it's triggered, which roles and
secrets it uses, and the gotchas. The **system view** (how a change ships) lives in the root
[`README.md`](../README.md#ci--cd); this file is the implementation detail. The **process**
(branching, the required-checks table, issues/labels, releases) lives in
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Naming conventions

- **File names** — task-only names for single-purpose files (`ci.yml`, `checks.yml`, `deploy.yml`,
  `release.yml`, `terraform.yml`, `cloudfront.yml`); `{task}-{env|language|resource}` once a repo
  grows a second file for the same kind of job. The deploy caller is `deploy.yml`; the
  per-environment reusables it calls are `deploy-{env}.yml`.
- **Display names** — quoted `{Category}: {Task}` (a colon+space is invalid unquoted YAML):
  `ci` · `Checks: {language}` · `Deploy: {env} {target}` · `Infra: {task}`.
- **`workflow_run` matches display names** — the deploy workflow watches `ci`; renaming a
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

Three files. [`deploy.yml`](deploy.yml) is the **caller** — the trigger plus one job per
environment — and [`deploy-staging.yml`](deploy-staging.yml) /
[`deploy-prod.yml`](deploy-prod.yml) are the **local reusable workflows** holding that
environment's jobs. Each caller job calls its environment's reusable, so the called jobs render
**nested under the calling job** — the run graph reads as two environment groups, and every check
name carries its environment:

| Caller job | Calls | Reported check names | Environment | Target |
| --- | --- | --- | --- | --- |
| `staging` | `deploy-staging.yml` | `staging / detect` · `staging / aws-s3` | `staging` (ungated) | `<project>-staging-site` (S3 + CloudFront) |
| `prod` | `deploy-prod.yml` | `prod / detect` · `prod / aws-s3` · `prod / github-pages` | `prod` (required reviewer) | `<project>-prod-site` + GitHub Pages (canonical) |

- **Each group's `detect` answers its own environment's question** (this replaced one top-level
  `detect` answering for both). Staging needs a **push to `main`**; prod needs a real **`v*` tag**.
  The caller `if:` is only the cheap eligibility test — ci succeeded and the ref is `main` or `v*` —
  and is deliberately loose, because the payload cannot tell a tag from a branch of the same name.
  Prod's `detect` resolves that for real (`repos/…/git/ref/tags/<name>`; a 404 means it was a
  branch) before anything prod runs, and staging's needs no token at all (`permissions: {}`, no
  checkout — the answer is in the event payload).
- **The gates live in the callee because they have to.** A job that calls a reusable workflow may
  carry only `name`/`uses`/`with`/`secrets`/`strategy`/`needs`/`if`/`concurrency`/`permissions` —
  **`environment:` is rejected** (GitHub's supported-keyword list for reusable-calling jobs). So
  each callee job declares its environment literally, which is a second win: no classification can
  resolve to an unprotected name. The callees are **local** files, so the gate sits one commit from
  the workflow it guards — a library hop would put it behind a cross-repo pin.
- **`permissions` on a calling job is a CEILING.** A called workflow can only downgrade, never
  elevate, so each caller job grants the union its callee's jobs need (`contents: read`,
  `actions: read`, `id-token: write`, plus `pages: write` on the prod group) and each callee job
  narrows per job — only `github-pages` carries `pages: write`.

- **The logic is still two composite actions** beside the caller:
  [`aws-s3`](../actions/aws-s3/action.yml) — download the artifact, assume the **deploy role**
  (OIDC), `aws s3 sync` to the bucket root, then assume the **invalidate role** for an inline `/*`
  invalidation (lookup by the `<project>-<env>-site` comment convention; skip when the distro is
  absent) — and [`github-pages`](../actions/github-pages/action.yml) — configure → upload → deploy,
  never touching AWS. One S3 action serves both environments; the environment token and `hash_skip`
  (`"true"` for staging only) are what differ. Composites still **cannot read `secrets`**, so every
  sensitive value arrives through `with:` — the artifact token is `github.token`, which composites
  can read — and the caller passes the rest down with `secrets: inherit`.
- **The AWS jobs check the repo out first, and that is not optional.** `uses: ./...` resolves from
  the JOB WORKSPACE, so the action cannot exist until the checkout has run — even though the action
  itself only needs the artifact (learned the hard way: the staging job failed its first main push
  after #70 with `Can't find 'action.yml'`). A remote action ref would not need the step.
- **Why not one `aws-s3` job serving both environments** (the shape this replaced):
  `environment: name: ${{ needs.detect.outputs.target }}` works, but it collapses both environments
  into one check name, one un-nested box, and a name that is data rather than a literal. Splitting
  per environment costs one extra `detect` runner per run and buys exact names
  (`staging / aws-s3` ≠ `prod / aws-s3`), a literal guard per file, and the grouped graph.

- **`environment:` is load-bearing, not decoration.** A job that declares one presents the OIDC
  sub `repo:OWNER/REPO:environment:<name>` instead of the ref form, and AWS STS accepts only the
  shapes listed in the deploy roles' trust (`scripts/bootstrap_aws.sh` — `ref:refs/heads/main`,
  `environment:staging`, `environment:prod`). So `environment:prod` had to be added to that trust
  **before** the AWS prod job was gated; renaming an environment without updating the trust breaks
  every AWS assume. The env-form sub also carries no ref, so a tag-only job is enforced by its own
  `detect`, never by the trust — the reviewer is what restrains it.
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
- **`cloudfront.yml`** — the one manual CloudFront entry point (dispatch, `operation:
  invalidate|switch`). It holds no AWS logic: each job calls a **shared reusable leaf** in the
  public `mathewmusango/my-workflows` library, SHA-pinned — `cloudfront-invalidate.yml` (purge;
  `environment` + `paths`, role chosen per environment) and `cloudfront-switch.yml` (flip
  `Enabled` in place; `component` × `mode` `on|off`). Distinct from the deploy workflow, which
  invalidates **inline** after each sync.
- **Switch is staging-only in practice** — the role passed is the staging edge-toggle role, so a
  prod distribution cannot be touched even though the leaf accepts an `environment`; least
  privilege is what enforces it. Caveat: `Enabled` lives outside terraform state, so the next
  apply restores `enabled=true`.
- **No script copy lives here** — the leaves are the single implementation, so a local
  `scripts/*_cloudfront.sh` would be a second one that drifts. Read the leaf for the exact AWS
  calls when you need them outside CI. The inline invalidation inside the deploy action is
  separate and unchanged.

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

# Workflows

Every workflow in `.github/workflows/` — what it does, how it is triggered, which checks it reports, and the roles and secrets it uses.

Each file has its own section below. [`.github/`](../INDEX.md) indexes the folder, and the design decisions that outlived their pull requests are collected under [Design notes](#design-notes) at the end.

## Naming conventions

- **File names** — task-only for a single-purpose file (`ci.yml`, `checks.yml`, `deploy.yml`, `release.yml`, `terraform.yml`, `cloudfront.yml`); `{task}-{env|language|resource}` once a repo grows a second file for the same kind of job. The deploy caller is `deploy.yml`; the per-environment reusables it calls are `deploy-{env}.yml`.
- **Display names** — quoted `{Category}: {Task}` (a colon+space is invalid unquoted YAML): `ci` · `Checks: {language}` · `Deploy: {env} {target}` · `Infra: {task}`.
- **`workflow_run` matches display names** — the deploy workflow watches `ci`; renaming a display name means updating every reference.

## `ci.yml` (`ci`)

- **Triggers:** push to `main` and `v*` tags; pull requests to `main`.
- Runs the shared [`.github/actions/build-site`](../actions/build-site/action.yml) composite: pip cache, `mkdocs build --strict`, translation parity, `pip-audit`, internal link check, CSS sanity. **`site_url` and the metrics endpoint are baked into the artifact at build time**, so the trigger picks them — tags → the `PROD_*` secrets, `main` → `STAGING_*`.
- Uploads the built `site/` as an artifact (7-day retention).
- Ends with the **browser smoke check** — [`scripts/checks/browser.py`](../../scripts/checks/browser.py) serves the built site and drives the runner's headless Firefox at `/resume/`, `/es/resume/`, `/zh/resume/` and `assets/pdf-viewer.html`, failing when a page does not render or reports a script error. It rides the existing required `build` check, so no new check name is registered, and the job declares `timeout-minutes: 20`.

## `checks.yml` — Checks

- **One workflow, a shared library.** It holds no check logic: each job calls a reusable workflow hosted in `mathewmusango/my-workflows`, pinned to a commit SHA. The reusable paths below are relative to `mathewmusango/my-workflows/.github/workflows/`.
- **Triggers:** pull requests to `main` + manual dispatch.
- **Self-gating reusables:** each reusable runs its own `detect` job and gates on changed files — a surface whose files are untouched **skips and reports success**, so requiring every check never blocks an unrelated PR.

| Caller job | Reusable workflow | Reported check name |
| --- | --- | --- |
| `js` | `checks-js.yml` | `js / syntax` |
| `python` | `checks-python.yml` | `python / ruff` |
| `shell` | `checks-shell.yml` | `shell / shellcheck` |
| `terraform` | `checks-terraform.yml` | `terraform / fmt` · `terraform / validate` · `terraform / lint` |
| `yaml` | `checks-yaml.yml` | `yaml / syntax` · `yaml / actionlint` |
| `docker` | `checks-docker.yml` | `docker / hadolint` — a Dockerfile lint plus a `docker compose config` on every compose file |

- **Surfaces:** shellcheck on every `*.sh` and `.githooks/**` · `ruff` on `**/*.py` · `node --check` on `**/*.js` · actionlint plus a YAML parse on `**/*.yml`/`**/*.yaml` (workflow edits self-validate) · the terraform stages on `terraform/**` and `.tflint.hcl` (`fmt -check`, `validate` on all three roots, TFLint — no AWS credentials) · hadolint on every `Dockerfile*` plus `docker compose config` on every compose file.

## `security.yml` — Security

- **The same shape, the same trigger, split by concern.** These are the security tools rather than the linting surfaces; two of them read a secret and reach a third party, which stays visible here — and this is the part the local stack deliberately does not mirror.
- **Moving a job between this file and `checks.yml` does not rename it:** the reported name comes from the caller job key, so the split needed no ruleset edit.

| Caller job | Reusable workflow | Reported check name |
| --- | --- | --- |
| `secrets` | `security-gitleaks.yml` | `secrets / gitleaks` |
| `gitguardian` | `security-gitguardian.yml` | `gitguardian / gitguardian` — needs the `GITGUARDIAN_API_KEY` secret; **not** a required check |
| `deps` | `security-deps.yml` | `deps / dependency-review` — PRs only |
| `terraform` | `security-terraform.yml` | `terraform / security` — Checkov, currently informational |

- **Scanners:** `gitleaks` covers provider patterns and entropy; `gitguardian` adds secret *validity* checking — telling a live credential from a dead example — via the `GITGUARDIAN_API_KEY` repository secret. `terraform` is the Checkov scan of `*.tf`, currently `soft_fail` while the audit backlog lands, and `dependency-review` reads the PR diff.
- **The reported names, not the reusable workflows' own names, are what the ruleset requires** — GitHub composes them as `<caller job key> / <leaf job name>`; the set is in [`rulesets/main.md`](../../rulesets/main.md).
- **Local parity:** [`containers/checks/`](../../containers/checks/README.md) mirrors the surfaces above (one service per check, identical tool images), driven by [`scripts/checks/local.sh`](../../scripts/checks/local.sh) and wired into the pre-commit hook. The GitHub workflows remain the authoritative gate.

## Branch names

Not a workflow. The [`branches: all`](../../rulesets/all.md) ruleset enforces them — a `create:`-triggered check fires only after the ref exists, so it could report but never prevent.

## Deploy — `workflow_run` on ci success

Three files. [`deploy.yml`](deploy.yml) is the **caller** — the trigger plus one job per environment — and [`deploy-staging.yml`](deploy-staging.yml) / [`deploy-prod.yml`](deploy-prod.yml) are the **local reusables** holding that environment's jobs, so the called jobs render nested under the calling job and every check name carries its environment:

| Caller job | Calls | Reported check names | Environment | Target |
| --- | --- | --- | --- | --- |
| `staging` | `deploy-staging.yml` | `staging / detect` · `staging / aws-s3` | `staging` (ungated) | `<project>-staging-site` (S3 + CloudFront) |
| `prod` | `deploy-prod.yml` | `prod / detect` · `prod / aws-s3` · `prod / github-pages` | `prod` (required reviewer) | `<project>-prod-site` + GitHub Pages (canonical) |

- **Each group's `detect` answers its own environment's question.** Staging needs a **push to `main`**; prod needs a real **`v*` tag**. The caller `if:` is only the cheap eligibility test — ci succeeded and the ref is `main` or `v*` — and is deliberately loose, because the payload cannot tell a tag from a branch of the same name. Prod's `detect` resolves that for real (`repos/…/git/ref/tags/<name>`; a 404 means it was a branch) before anything prod runs, and staging's needs no token at all (`permissions: {}`, no checkout — the answer is in the event payload).
- **The gates live in the callee because they have to.** A job that calls a reusable workflow may carry only `name`/`uses`/`with`/`secrets`/`strategy`/`needs`/`if`/`concurrency`/`permissions` — **`environment:` is rejected**. So each callee job declares its environment literally, and because the callees are **local** files the gate sits one commit from the workflow it guards.
- **`permissions` on a calling job is a CEILING.** A called workflow can only downgrade, never elevate, so each caller job grants the union its callee's jobs need (`contents: read`, `actions: read`, `id-token: write`, plus `pages: write` on the prod group), and each callee narrows per job — only `github-pages` carries `pages: write`.
- **The shared AWS logic is one composite action** — [`aws-s3`](../actions/aws-s3/action.yml): download the artifact, assume the **deploy role** (OIDC), `aws s3 sync` to the bucket root, then assume the **invalidate role** for an inline `/*` invalidation (lookup by the `<project>-<env>-site` comment convention; skip when the distro is absent). It serves both environments; the environment token and `hash_skip` (`"true"` for staging only) are what differ. A composite cannot read `secrets`, so its values arrive through `with:`. The **Pages steps are inline** in the prod callee — they run once, and that job needs **no checkout**: every step is a remote action.
- **Secrets are mapped at the call, not inherited.** Each caller job passes the four secrets its callee declares (`secrets:` with `PROJECT`, `AWS_REGION`, `DEPLOY_ROLE_ARN`, `INVALIDATE_ROLE_ARN`) instead of `secrets: inherit`, so a callee sees exactly what it uses.
- **Job hardening:** an explicit `timeout-minutes` on every deploy job (5 for a `detect`, 15 staging / 30 prod), and a **per-environment `concurrency` group on the AWS planes** (`deploy-<env>-aws-s3`, `cancel-in-progress: false`) — two merges in quick succession would otherwise sync the same bucket at once, both with `--delete`. Queued rather than cancelled: a cancelled sync would leave the bucket half-updated. Pages keeps its `pages` group.
- **The S3 job checks the repo out first.** `uses: ./…` resolves from the job workspace, so the action cannot exist until the checkout has run. It is the only checkout left in the deploy.
- **Content-hash skip (staging).** A deploy on `main` skips sync and invalidation when the artifact is byte-identical to the last staging deploy: a zero-byte marker keyed by a SHA-256 of the site content under `.deploy-hash/<hash>`, existence-checked with `s3 ls` — the deploy role deliberately has **no `s3:GetObject`**, so the marker is written and listed, never read. The sync excludes `.deploy-hash/*` so the marker survives `--delete`. A day boundary can change the hash (git-revision-date embeds) — then it deploys as usual, never stale, best-effort.
- **`environment:` is load-bearing, not decoration.** A job that declares one presents the OIDC sub `repo:OWNER/REPO:environment:<name>` instead of the ref form, and AWS STS accepts only the shapes listed in the deploy roles' trust (`scripts/bootstrap_aws.sh` — `ref:refs/heads/main`, `environment:staging`, `environment:prod`). So `environment:prod` had to be added to that trust **before** the AWS prod job was gated; renaming an environment without updating the trust breaks every AWS assume. The env-form sub also carries no ref, so a tag-only job is enforced by its own `detect`, never by the trust — the reviewer is what restrains it.

## Release — `release.yml`

- **Triggers:** `v*` tags or manual dispatch. Packages `site.zip`, generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt`, and creates/refreshes a GitHub Release with notes from `CHANGELOG.md`.
- Releases do **not** drive deploys (tags do) — they publish the SBOM, artifact, and notes.

## Infra — `terraform.yml` + `cloudfront.yml`

- **`terraform.yml`** — the environment comes from the trigger: a push to `main` touching `terraform/**` → staging (**plan and auto-apply**), a `v*` tag → prod (**plan only**), and `workflow_dispatch` picks `action` (plan/apply) and `environment` (auto/staging/prod) by hand. **Prod is never auto-applied** — a blind auto-apply is how stacks get destroyed. One job per environment runs at a time: the `concurrency` group resolves from the same expression as the environment step, with `cancel-in-progress: false`, so a queued run waits for the in-flight apply rather than racing it for the state lock. There is deliberately no separate `validate` step — the plan validates the configuration, and the shared `checks-terraform` check runs fmt/validate/lint/security on PRs. AWS access is OIDC, with vars from the `STAGING_*`/`PROD_*` secrets (`*_TERRAFORM_ROLE_ARN`, `PROJECT`, `AWS_REGION`, `*_ALLOWED_ORIGIN`). **Free-Tier default:** the private VPC and WAF are off (`enable_vpc`/`enable_waf` false — the Logs VPC endpoint and WAF sit outside the Free Tier); the Lambda origin gate (403 for non-site origins) plus least-privilege IAM are the free controls, and geo headers come from CloudFront, so both environments get the edge. Flip the two vars for the hardened variant. Deep docs: [`terraform/README.md`](../../terraform/README.md).
- **`cloudfront.yml`** — the one manual CloudFront entry point (dispatch, `operation: invalidate|switch`). It holds no AWS logic: each job calls a **shared reusable leaf** in the public `mathewmusango/my-workflows` library, SHA-pinned — `cloudfront-invalidate.yml` (purge; `environment` + `paths`, role chosen per environment) and `cloudfront-switch.yml` (flip `Enabled` in place; `component` × `mode` `on|off`). Distinct from the deploy workflow, which invalidates **inline** after each sync.
- **Switch is staging-only in practice** — the role passed is the staging edge-toggle role, so a prod distribution cannot be touched even though the leaf accepts an `environment`. Caveat: `Enabled` lives outside terraform state, so the next apply restores `enabled=true`.
- **No script copy lives here** — the leaves are the single implementation, so a local `scripts/*_cloudfront.sh` would be a second one that drifts.

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

ci/checks/release talk to the GitHub API with the auto-scoped `GITHUB_TOKEN` (Release elevates it to `contents: write` to create the Release). Deploys and Terraform assume **AWS roles via OIDC** — one least-privilege role per job per environment; the only key-based step is the out-of-band `terraform/bootstrap` bootstrap, run as an AWS user.

The per-environment role ARNs and deployment values live as **repo secrets** (Settings → Secrets and variables → Actions), referenced by name from the workflows. Names follow a fixed pattern (`ENV` ∈ `STAGING` / `PROD`):

| Pattern | Purpose |
| --- | --- |
| `{ENV}_DEPLOY_ROLE_ARN` · `{ENV}_INVALIDATE_ROLE_ARN` | S3 sync + edge purge roles |
| `{ENV}_TERRAFORM_ROLE_ARN` | plan/apply role |
| `{ENV}_TOGGLE_ROLE_ARN` | edge on/off flip (staging only) |
| `PROJECT` · `AWS_REGION` | shared — bucket naming, region |
| `{ENV}_ALLOWED_ORIGIN` · `{ENV}_METRICS_ENDPOINT` · `{ENV}_SITE_URL` | per-env build/run values |

Terraform variables (`project`, `environment`, `aws_region`, `allowed_origin`, `tags`) are injected from those secrets (CI) or `local.tfvars` (local dev) — nothing is hardcoded.

## Design notes

The reasoning behind the shapes above, kept out of the reference so each section stays a reference.

- **Why the gates sit in the callee, stated once more:** the reusable-calling job cannot carry `environment:`, so any gating there is impossible by the platform, not by preference. The local-callee choice then buys a one-commit gap between the gate and the workflow it guards, which a library hop would lose.
- **Why each environment has its own `detect`** (the shape that replaced one top-level `detect`): a single detector collapsed both environments into one check name and one un-nested box.
- **Why not one `aws-s3` job serving both environments:** `environment: name: ${{ needs.detect.outputs.target }}` works, but it collapses both into one check name, one un-nested box, and a name that is data rather than a literal. Splitting per environment costs one extra `detect` runner per run and buys exact names (`staging / aws-s3` ≠ `prod / aws-s3`), a literal guard per file, and the grouped graph shown above.
- **Why the S3 job checks out at all** — `uses: ./…` resolves from the job workspace, so the action cannot exist before the checkout; this failed the first post-#70 main push with `Can't find 'action.yml'`. Referencing the action as `owner/repo/.github/actions/…@<sha>` would remove the checkout too, at the cost of a same-repo pin nothing bumps automatically.
- **Why content, not commits, for the staging skip:** the old commit-diff gate (`HEAD~1..HEAD`) let multi-commit batches go stale, where a content comparison cannot — a skip only happens when the exact bytes to sync are already live.
- **Why the switch caveat exists:** `Enabled` is set outside terraform state, so terraform's next apply restores `enabled=true`; the workflow is a temporary flip, not a desired-state lever.

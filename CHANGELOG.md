# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

**Release policy:** event-driven, not time-driven — release when a coherent,
confirmed feature batch lands (no fixed schedule). Releases are provenance
snapshots (tagged source + site.zip + SBOM); the live site updates on every
push regardless. Versions are **timestamp tags** — `v<YYYY>.<MMDD>.<HHMM>Z`, e.g.
`v2026.0925.1228Z` — cut at release time and stamped `date -u`, so the `Z` is true.
A timestamp carries no severity, so a
breaking change is called out in the release notes rather than encoded in the
version.

**Unreleased section:** meaningful changes land under `## [Unreleased]` as they
are introduced via issues/PRs (a new section is opened by the first change of a
cycle). A release **renames** that section to its tag without the leading `v`
(`## [<year>.<MMDD>.<HHMM>] - date`) and adds no empty successor — the next
cycle's `## [Unreleased]` is opened by its first landed change.

## [Unreleased]

### Added
- **The `aws-s3` deploy action's body is executed before merge** — `scripts/checks/actions.py` ran `inject-env-urls`' body under the runner's flags but skipped the deploy action, whose bash steps carry `if:` conditions on step outputs and call the `aws` CLI. The harness now evaluates those `if:` conditions, substitutes `${{ }}` from inputs and step outputs, captures `$GITHUB_OUTPUT`, and runs the body with a stub `aws` on `PATH` that records each call. Three cases cover the branches: a release (`hash_skip=false`) always syncs with `--delete`, invalidates, and plants no marker; a first `hash_skip` deploy syncs and plants `.deploy-hash/<hash>`; an unchanged artifact (`changed=false`) syncs and invalidates nothing. It runs in `build`, so it gates merges (#184).

### Changed
- **The `tag: v*` ruleset requires signed commits** — every release path now verifies commit signatures: `branch: main` already carried `required_signatures`, and the tag ruleset (id `22227856`) gated only on `build` plus deletion, force-push and update. The rule checks the tagged commit's verified signature, not the tag object's, so a tag cut at a `main` tip changes nothing (already signed); it closes the gap for any tag that is not (#186).
- **The Release workflow no longer waits on a prod approval** — `release.yml` declared `environment: prod` only to read the prod `SITE_URL` / `METRICS_ENDPOINT` variables its build and inject steps need, so every tag push and manual refresh sat behind the `prod` reviewer even though the job touches no AWS or prod infrastructure — it builds `site.zip`, generates the SBOM, and creates the release. It now declares a new reviewer-free `release` environment carrying those two variables, and `prod` keeps its reviewer for the deploy and infra workflows (#190).
- **Terraform is split into generic per-service modules** — `terraform/modules/` held two product-named composites (`site`, `metrics`) with every resource inline, and the `archive` provider carried a `~> 2.0` ceiling in both the root and the metrics module (the Dependabot intersection trap). It now holds seven generic AWS-service leaves — `s3`, `cloudfront`, `dynamodb`, `lambda`, `api-gateway`, `vpc`, `waf` — each secure-by-construction (a private, public-access-blocked bucket; an OAC-scoped bucket policy; least-privilege IAM only from the policies handed in) and free of portfolio vocabulary, so a leaf can be reused in another Terraform root unchanged. The two composites remain, but only as wiring: `site` supplies its directory-index and localized-error functions to `cloudfront` as data, and `metrics` composes the VPC, DynamoDB schema, two Lambda functions (the writer/reader split now lives in the composite), API Gateway routes and the optional WAF. `lambda` is exactly one function per module; the build-once zip is produced by the composite and passed in. Provider floors resolve the `archive` trap. Every address change is covered by a `moved` block, so the plan stays a no-op (#193).
- **Terraform is split into `bootstrap` + `infra/{site,metrics}` roots** — the single combined root (one state at `metrics/terraform.tfstate`) becomes three, each with its own state, provider pin and lockfile: `infra/site` (`site/terraform.tfstate`) and `infra/metrics` (`metrics/terraform.tfstate`), with `bootstrap` kept at the top as the out-of-band foundation and the reusable service wrappers under `terraform/modules/`. Each root now creates its own security-headers policy, since separate states cannot share one. A new generic `modules/iam` (role + inline/managed policy attachments) backs `modules/lambda`'s execution role and least-privilege policies. `terraform.yml` becomes two jobs (`site`, `metrics`) that each run the environment resolved by `detect`; apply stays a manual `workflow_dispatch` until the one-time state migration lands, then a one-line change enables auto-apply (main→staging, tag→prod behind the `prod` reviewer). The site bucket, the DynamoDB table and both CloudFront distributions carry `prevent_destroy` guards (Terraform-side), and the metrics table — plus the state-lock table — is protected from deletion at the AWS API, so an accidental delete fails rather than removes. Because the two roots no longer share the combined root's state, that migration is adopt-never-recreate (#195, #194).
- **The metrics site-origin is derived, not injected** — the two-root split left the metrics CORS / edge origin-gate allow-list needing the site's CloudFront domain across roots, injected as a per-environment `SITE_ORIGIN` variable (drift-prone, plus a manual first-run step). The metrics root now reads the site root's state (`data "terraform_remote_state" "site"`, same per-env bucket, key `site/terraform.tfstate`) and derives the allow-list entry from its `distribution_domain_name` output; the `SITE_ORIGIN` variable and the workflow's `TF_VAR_extra_allowed_origins` wiring are retired. Local (Ministack) dev reads the local site state via a `site_state_bucket` override, and the documented order becomes site-then-metrics. The `metrics` workflow job now declares `needs: [detect, site]`, so CI always runs the site stack first (#200).

### Fixed
- **A missing site state no longer fails the metrics plan** — the metrics root read the site root's state unconditionally, and `terraform_remote_state` hard-errors (*Unable to find remote state*) when the object is absent, so every `Deploy: Infra` run failed on the metrics stack until the site state existed and a fresh account could not plan at all. The read is now gated on the object's existence — `data "aws_s3_objects"` over the state key returns an empty `keys` list when it is absent and never errors, and that decides a `count` — so the metrics root plans with the site origin omitted. A `check` block asserts the derived origin is non-empty, so the only signal when the site state is missing is a **warning** naming the bucket and key and telling the operator to apply `terraform/infra/site` first (#202).
- **The release hook now recognises a timestamp tag, so the tag-promotion row renders again** — `scripts/releases_hook.py` guarded its tag promotion with `TAG_RE = ^v\d+\.\d+\.\d+$`, which accepts only the legacy SemVer form; the current scheme's trailing `Z` (`v2026.1002.1733Z`) was refused, so `_current_tag()` returned `""` on every tag build and the just-released version stayed out of the generated release timeline and the Site Atlas rows until the separate manual promotion landed. The guard is now `^v\d+\.\d+\.\d+Z?$` — the timestamp form matches, and historical `v3.x.y` tags still do (#182).

## [2026.1002.1733Z] - 2026-10-02

### Fixed
- **The Release is now titled with its tag** — `release.yml` created every GitHub Release as `Release <tag>`, so the name duplicated what the tag already said and read as a prefix in the Releases list. It now passes `--title "${TAG}"` — and, the part that actually mattered, `gh release edit` sets the title too. The refresh path previously passed no title at all, so re-running the workflow over an existing release preserved whatever title was there, wrong ones included, which is why a first-release correction needed a second pass. The four releases already carrying the prefix are corrected through the API.
- **`github-pages / prod` can resolve its local action again** — the job carries no `actions/checkout` (it reads the CI artifact, never the tree), but #157 gave it `uses: ./.github/actions/inject-env-urls`, and the runner loads a local action out of the workspace. The step therefore failed with *Can't find 'action.yml' … Did you forget to run actions/checkout?* before substituting anything, leaving prod's gh-pages stale while `aws-s3 / prod` — which does check out — succeeded, so prod's two planes drifted. The checkout is restored as the job's first step: the reason for omitting it stopped holding the moment the job began using a local action. This is a class neither `actionlint` nor the composite-body check sees — the action body is valid; the fault is the job's wiring.
- **A job that uses a local action without checking out now fails the check** — the fault behind the entry above had no detector on it: `actionlint` validates each workflow in isolation and the composite-body check runs bodies, not wiring, so `github-pages / prod` stayed broken from #157 until #171. `scripts/checks/actions.py` now walks every job's steps in order and fails when a `uses: ./…` has no preceding `actions/checkout` — the runner loads a local action out of the workspace. It runs in the same `build`-job step, so it gates pull requests, and it names both the job and the step: *deploy.yml: job 'github-pages-prod' uses ./.github/actions/inject-env-urls before any actions/checkout*.

### Changed
- **The analytics Geo block names countries instead of showing their codes** — the map tooltips and the country legend rendered the raw ISO alpha-2 key (`KE — 12 (40%)`), which reads as a code rather than a place. `geo-map.js` now exposes a `countryName` helper backed by `Intl.DisplayNames`, and `renderPie` takes an optional label formatter that only the geo call site passes, so the map and the country legend show `Kenya` while the languages pie keeps its own keys. The name follows the page language (`es`/`zh` included) for free, an unrecognised key such as `unknown` passes through unchanged, and the country codes stay the data keys because the map resolves each centroid by them.

## [2026.1002.1602Z] - 2026-10-02

### Added
- **A browser smoke check now gates the build** — `scripts/check_browser.py` serves the built site, injects a probe into the four viewer pages (`/resume/`, `/es/resume/`, `/zh/resume/`, `assets/pdf-viewer.html`), drives the runner's preinstalled headless Firefox at each, and fails when a page does not render or reports a script error. It runs as the last step of `build.yml`'s `build` job — which already produces `site/` and is already a required check — so it gates merges without registering a new check name or paying for a second build. The build job also gains an explicit `timeout-minutes: 20`. Added because the pdf.js v6 API regression in #95 passed the strict build, CodeQL **and all twelve required checks** while the resume was broken at runtime (#103).
- **Dependabot now sees Terraform, and lands updates in groups** — the three committed `.terraform.lock.hcl` files (`terraform/`, `terraform/ci/`, `terraform/modules/metrics/`) were invisible to Dependabot, so a provider advisory could never surface; each gains a `terraform` ecosystem entry. Every block also gains `groups` — minor + patch land as one PR per ecosystem, majors stay individual — and the schedule unifies on weekly, replacing the mixed monthly `github-actions` cadence that no other block followed. Labels stay to the ones the repo actually has (`dependencies`, plus `github-actions` where already used), because inventing `pip`/`npm`/`terraform` labels is a governance change rather than a config one (#104).
- **The vendored JavaScript finally has a manifest, so Dependabot stops being blind to it** — a root `package.json` + `package-lock.json` pin Mermaid, pdf.js and Tablesort at exactly the versions vendored under `docs/assets/`, and `.github/dependabot.yml` gains the missing `npm` ecosystem entry (it watched only `pip` and `github-actions` before, so no manifest could ever have been read). The manifest is bookkeeping only — nothing is installed or built from it, and `node_modules/` stays ignored — but it populates the dependency graph, so advisories now alert on the vendored libraries *and* their transitive trees (Mermaid's bundled DOMPurify included). One consequence to remember: a Dependabot bump moves the pin, not the vendored file, so any bump must re-vendor in the same change. The file also carries `"type": "module"`, which is load-bearing for the JS check rather than cosmetic (#94).
- **A composite action's `run:` body is now executed before merge, not after it** — `inject-env-urls`' body ran only inside a deploy, so when its bare-form pass could never match (the built `site_url` is always slash-terminated, and the slash pass consumes every occurrence first) the resulting `grep` exit 1 aborted the step under `bash -e -o pipefail` **before** it printed anything, failing every site-changing deploy with a bare `Process completed with exit code 1` — invisible to `actionlint`, `shellcheck` and every required check, none of which executes a body. `scripts/checks/actions.py` reads each body straight from its `action.yml`, runs it under the runner's exact shell flags against fixtures, and asserts the outcome: the empty-match abort is rejected, a slash-less occurrence must be substituted rather than left to trip the guard, an absent metrics endpoint must be a no-op, and a missing placeholder must fail loudly with `::error::`. It runs as a step of the `build` job — which always runs on a pull request and is already required — so it gates merges without a new check name.

### Changed
- **A release no longer needs a CHANGELOG edit first** — `release.yml` found its notes with a heading match on the tag, so cutting a release meant renaming `## [Unreleased]` to the tag heading beforehand or shipping the `See CHANGELOG.md for details.` fallback. It now falls back to the `## [Unreleased]` section when the tag has no heading yet, which takes that step off the release's critical path; a versioned section is still preferred when it exists, so a backfill of an old tag uses its own. Renaming inside the release job was not an option — it runs on the tag ref, and a commit to `main` is refused by the branch ruleset (`pull_request` required, `bypass_actors: []`), and a release job is the wrong place to write repo content anyway. The section still has to be cleared after a release or the next one repeats it, so that becomes post-release housekeeping rather than a prerequisite.
- **Three workflows are named for what they act on** — `Deploy` becomes **`Deploy: Code`**, `Infra: Terraform` becomes **`Deploy: Infra`** (it plans and applies, so it belongs in the deploy family), and `Infra: CloudFront` becomes **`Override: CloudFront`** (a manual edge override, not an infra deploy). Renaming a workflow `name:` is safe here and was checked first: the repo's only `workflow_run` is `deploy.yml`'s `workflows: ["build"]`, which names `build` — not renamed — and none of the three feeds a required status context, which are job-derived (`build`) or come from `checks.yml`'s caller keys (`terraform / validate`, …).
- **The build no longer bakes the target environment in, so one artifact is valid everywhere** — `SITE_URL` and `METRICS_ENDPOINT` were repository variables with `PROD_`/`STAGING_` prefixes, selected **by ref** in `build.yml` (and hardcoded to prod in `release.yml`), so a tag build and a `main` build were two different artifacts and there was nothing to promote. `build-site` now bakes **placeholders** in the RFC 2606 reserved domain (`https://site-url.invalid/`, `https://metrics-endpoint.invalid`) as its input defaults, and a new composite, **`.github/actions/inject-env-urls`**, substitutes the target environment's real values at deploy time — in `aws-s3` right after the artifact lands and **before** the content-hash check, so the hash covers what is actually deployed, and in the gh-pages job before the artifact is uploaded. It asserts the placeholder was present first, that no placeholder host survives (the first cut matched any `.invalid`, which the vendored mermaid and pdf.js bundles legitimately contain), and that `site_url` ends in `/` (a slash mistake would otherwise double or drop the separator), so a drifted placeholder fails the deploy instead of quietly serving a broken domain. The two values become environment **variables** on `staging`/`prod` and the four prefixed repo variables are retired. One consequence: **`release.yml` declares `environment: prod`** — it rebuilds the artifact it attaches to the release, so it needs the prod values and the environment is the only scoped source; the release job therefore waits on the same reviewer the prod deploy does.
- **`detect` now decides on the ref and on the changed paths** — two decisions were missing. **A prod run must be a tag:** `cloudfront.yml` gained a `detect` job and `terraform.yml`'s gained a guard, so a `prod` target off a branch fails loudly instead of running — a prod CloudFront `switch` had been dispatched from `main`. (`deploy.yml` already resolved prod only from a real `v*` tag; each guard stays inline in its own workflow rather than in a shared action.) **A deploy only runs when the site could have changed:** `build.yml` gained a `detect` job that diffs the push (`github.event.before..sha`, the multi-commit range the old `HEAD~1..HEAD` gate never had) against the paths the site build consumes — `docs/**`, `mkdocs.yml`, `overrides/**`, `requirements.txt`, the two `mkdocs` hooks, `.github/actions/build-site/**`, plus a `CHANGELOG.md` whose *released* headings moved (the releases hook skips `[Unreleased]`, so an ordinary Unreleased entry does not count) — and **skips the build** when none did. No `site` artifact is then produced, so `deploy.yml`'s `detect` finds none and skips too: no environment-gated job is created, so nothing waits on a reviewer for a deploy that would change nothing, and the rebuild is not paid for. Pull requests and tags always build (`workflow_dispatch` on `build.yml` is the force-deploy escape hatch, and `deploy.yml` maps a dispatched build on `main` to staging).
- **The terraform job serves both environments from one body, and a prod run is now reviewed** — `terraform.yml` keeps a **single** `terraform` job (the environment was already a resolved value), but it now **declares `environment:` from a `detect` job's output**, so `TERRAFORM_ROLE_ARN` resolves from the target environment instead of the repository, and a prod run waits on the `prod` environment's required reviewer — a standing want, and the same posture the deploy jobs already have. The target is resolved once, and both `environment.name` and the per-job concurrency group read that single output. Two knock-ons: the **terraform role's OIDC trust gained the environment form** (`environment:staging` / `environment:prod`) because an environment-declaring job's `sub` carries no ref — so the prod role is no longer `v*`-only *by trust*, and that intent now rests on the workflow's own resolution plus the reviewer gate (the same trade the deploy role took in #57) — and the repo-level `AWS_REGION` variable and the two `{PROD,STAGING}_TERRAFORM_ROLE_ARN` secrets become unread and are retired. A `v*` tag push therefore leaves a prod plan job awaiting approval.
- **The CloudFront jobs are plain jobs reading their role ARNs from the target environment — and prod finally has a toggle role** — `cloudfront.yml` was the last workflow calling library reusables (`cloudfront-invalidate.yml` / `cloudfront-switch.yml`), and a job that calls a reusable cannot declare `environment:`, so its ARNs had to stay repository-level and the `switch` operation could only ever present the **staging** toggle role. Both jobs are now inlined as plain jobs that declare `environment: ${{ github.event.inputs.environment }}` and read `INVALIDATE_ROLE_ARN` / `TOGGLE_ROLE_ARN` from that environment, with no `secrets:` mapping — one name per environment, and the `prod` reviewer gate the deploy jobs carry now covers a prod dispatch too (it did not before). Because prod is a real target now, `terraform/bootstrap/main.tf` drops the `count` that gated the toggle role, policy and attachment off prod (`var.environment != "prod"`, a 2026-08-29 decision) and re-addresses them with reverse `moved` blocks (`[0]` → unindexed) so staging's state is renamed rather than replaced; the library leaves lose their only consumer. Lands with the prod bootstrap re-run and `TOGGLE_ROLE_ARN` added to the `prod` environment, so the plumbing exists before the workflow reads it.
- **The deploy is one workflow of plain jobs, and each reads its role ARNs from its own environment** — `deploy-staging.yml` and `deploy-prod.yml` are gone, and so is the pair of plane reusables that briefly replaced them: `deploy.yml` now holds a single **`detect`** job plus three plain jobs, `aws-s3 / staging`, `aws-s3 / prod` and `github-pages / prod`. The detect answers both questions once — a push to `main` → staging; a real `v*` tag, resolved against the API → prod — and the three jobs gate on its outputs. **Because they are plain jobs they can declare `environment:` themselves, so `DEPLOY_ROLE_ARN` / `INVALIDATE_ROLE_ARN` resolve from the environment with no `secrets:` mapping at all**: one name per environment, and a staging job cannot see prod's role. Two earlier attempts failed precisely because a *called* workflow cannot read environment secrets — its `secrets` context holds only what the caller passes or inherits, proven on 2026-09-30 — and a calling job cannot declare `environment:`; plain jobs are the only shape that gets both. It also restores two guardrails the reusable layer had given up: `environment:` is a **literal per job** again, so no computed name can land an unprotected environment, and the gate holds its token in a job of its own rather than inside the staging deployment. The S3 plane stays one implementation (`.github/actions/aws-s3`, shared through its `env` token); the run graph is flat job names rather than nested groups — the one thing #72's reusable layer bought, and the price of this shape.
- **The deploy's configuration is no longer dressed as a credential** — `PROJECT`, `AWS_REGION` and the two per-environment `ALLOWED_ORIGIN` values moved from secrets to repository **variables** — a project name, a region and a public origin, with `PROD_ALLOWED_ORIGIN` and `STAGING_ALLOWED_ORIGIN` holding the *same* value, so nothing needed masking and nothing could be read back. Because a repository secret cannot reach a called workflow that is not passing it, the deploy callees now take `project` / `aws_region` as `workflow_call` **inputs** — which is what they always were — removing the caller's `secrets:` mapping for those two; `terraform.yml` and `cloudfront.yml` read the variables directly, and `ALLOWED_ORIGIN` loses its `PROD_ || STAGING_` ternary. **The role ARNs stay repository-level and are passed by the caller — an environment secret cannot reach a called workflow at all.** Two attempts to scope them failed the staging deploy with *Credentials could not be loaded*: first with the names declared `required: false` in `on.workflow_call.secrets` (the declaration closes the `secrets` context's type — which is why `actionlint` demands it — *and* creates an empty binding), then with no `secrets:` block at all. A `workflow_call` callee's `secrets` context is populated only from what the caller passes or inherits, and a job's `environment:` does not supply it. Environment-scoping these values therefore requires the jobs to be **plain jobs** (where `environment:` does supply secrets), not a reusable's; until then the caller maps them from the repository, as before (#142, #143).
- **A build can no longer silently target the wrong environment** — `site_url` and `metrics_endpoint` were read from four repo-level secrets with no validation, and both are baked into the artifact (`site_url` drives canonical/OG/sitemap/hreflang; `metrics_endpoint` becomes the `<meta name="metrics-endpoint">` tag the beacon no-ops without). The composite action defaulted both inputs to empty, so a renamed or unset value **skipped the `site_url` injection entirely** — falling back to `mkdocs.yml`'s canonical — and silently disabled the beacon, and nothing could answer "is it set?" because secrets are masked. The four values move to repository **variables** (`PROD_`/`STAGING_SITE_URL`, `PROD_`/`STAGING_METRICS_ENDPOINT`), which render in the UI and unmasked in logs; `.github/actions/build-site` now validates them — an empty or non-`https://` `site_url` fails the build, `metrics_endpoint` may stay empty ("beacon disabled") but must be a URL when set — and echoes the resolved target as an audit line. `release.yml` passes the prod values, so the released `site.zip` is the site that deployed rather than one built with empty inputs and the beacon off (#140, #139).
- **The build workflow is named for what it does** — `ci.yml` becomes `build.yml` and its `name: ci` becomes `name: build`, so the Actions list, the README badge and every doc say build rather than naming the phase the workflow belongs to. `deploy.yml`'s `workflow_run` moves with it in the same change, because that trigger matches a workflow's literal `name:` field and not its filename. No ruleset changes: the required contexts are job-derived (`build`, `python / ruff`, … on `main`; `build` on `tag: v*`), so the `build` **job** stays exactly where it is (#137).
- **Two names now say what the thing is** — `terraform/ci` becomes `terraform/bootstrap` (it creates the OIDC identity and the state backends in a one-time, hand-run apply; "ci" named a consumer rather than the job) and the dev container moves from `containers/mkdocs` to `containers/site` (the tool's name to the product's, matching `modules/site`). Every reference moved with them — the check stack's `-chdir`, the Dependabot directory entry, the bootstrap script, the workflows README, the root README and all three translated doc sets. **The bootstrap root's state key deliberately stays `ci/terraform.tfstate`**: the key is where live state lives, so moving it would orphan the state, and the divergence is now documented in `terraform/README.md`. The container move is only safe because `.gitignore` anchors `/site/` — a bare `site/` would have silently ignored the new directory, exactly as it did to `modules/site`.
- **The check stack stops re-downloading Terraform providers and the TFLint ruleset on every run** — `terraform-validate` fetched aws + archive for each root on each invocation, and `tflint --init` re-fetched its ruleset, because nothing persisted between containers. Both now write to named volumes (`tf-plugins` behind `TF_PLUGIN_CACHE_DIR`, `tflint-plugins` behind the lint plugin dir), so only the first run pays; the repo mount stays read-only, so the caches never touch the working tree.
- **The site moved into `modules/site`, so the root is now composition only** — `main.tf` carried the site inline (bucket, SSE config, public-access block, OAC, the OAC policy document, bucket policy, the distribution and its two edge functions) while the metrics product sat behind `modules/metrics`; the asymmetry is gone and the root is now two module calls plus the wiring between them. `moved` blocks re-address every relocated resource in state, so **no infrastructure is replaced** — a plan that is not a no-op is the bug, and the blocks can be dropped once staging and prod have both applied them. The new module declares the same provider **floor** as `modules/metrics` and is not a root (no `validate` stage, no lockfile, no Dependabot entry). The security-headers policy the site **and** metrics distributions both attach stays in the root, since a resource two products share belongs to neither. `terraform/README.md` gains the four-axis reading guide this layout encodes.
- **A child module no longer pins a provider major, so provider bumps are mergeable again** — `terraform/modules/metrics` required `aws ~> 5.0` while the root required the same, and Terraform intersects every constraint in the call graph, so the two per-directory Dependabot PRs that raised the provider to 6.x (#109, #110) could not both land: whichever merged first left the other's constraint unsatisfiable, `terraform init` failed for the root, and the required `terraform / validate` check went red — in *every* merge order. The module now declares a floor (`aws >= 5.0`) and the root owns the pin (`~> 6.65`), which is the correct shape for a child that only the root ever calls; both lockfiles re-lock to aws 6.66.0 from Dependabot's own output rather than hand-written hashes, and the module directory is no longer treated as its own Terraform root at all: it is neither a `validate` target nor a Dependabot directory, so no per-module bump can exist to collide with the roots; the root and `terraform/ci` keep majors, which is how 6.x legitimately arrived (#116).
- **Manual CloudFront ops consolidated and shared** — `invalidate-cloudfront.yml` + `toggle-env.yml` become one dispatch entry point, `cloudfront.yml`, whose two jobs call shared reusable leaves in the public `my-workflows` library (`cloudfront-invalidate.yml`, `cloudfront-switch.yml` — the latter flipping `Enabled` with `mode: on|off` — pinned `@0f6fa47` `# v2026.0917.2243`). A reusable is right here and wrong for deploy, for the same reason inverted: these are dispatch ops with an environment *input*, so there is no reviewer gate to lose. The AWS logic now lives once for every project using the `<project>-<env>-<component>` comment convention, and this repo's two script copies were **deleted** rather than kept as a second implementation; the deploy action's inline invalidation is unchanged.
- **Deploy hardening — tighter jobs, explicit secrets, no wasted checkout** — the prod Pages steps are now inline in `deploy-prod.yml` (they run once, so the composite was indirection with nothing to share — and it cost a full `actions/checkout` in that job purely so `uses: ./…` would resolve; the deploy reads the ci **artifact**, never the tree, so the Pages job no longer checks out at all). Every deploy job gained an explicit `timeout-minutes` (5 for a `detect`, 15 staging / 30 prod — the platform default is 360), the AWS planes are serialized per environment (`concurrency: deploy-<env>-aws-s3`, `cancel-in-progress: false`, so two quick merges cannot sync the same bucket at once, both with `--delete`; queued rather than cancelled, because a cancelled sync would leave the bucket half-updated), and each caller job now maps the four secrets its callee declares instead of `secrets: inherit`. The one checkout left is the S3 job's, which `uses: ./.github/actions/aws-s3` requires.
- **One deploy workflow, two environments — and the run graph shows it** — the three per-target workflows (`deploy-staging-s3.yml` + `deploy-pre-prod-s3.yml` + `deploy-prod-pages.yml`) collapse into `deploy.yml` (the caller: the trigger plus one job per environment) and two **local reusable workflows** that hold each environment's jobs, `deploy-staging.yml` and `deploy-prod.yml`. A called workflow's jobs render nested under the calling job, so a deploy now reads as two environment groups — `staging / detect` · `staging / aws-s3` · `prod / detect` · `prod / aws-s3` · `prod / github-pages` — and **each group's `detect` answers its own question**: staging requires a **push to `main`**, prod requires a real **`v*` tag** (resolved against the API, so a branch named like a tag is no longer mistaken for one and the `build`-failure case is decided in one place). The retired `pre-prod` name is gone for good: the AWS plane (S3 + CloudFront, `<project>-prod-site`) has always *been* prod, so it is named prod. **Both prod planes are gated** by the `prod` environment's required reviewer — staging stays automatic — and because gating the AWS plane moves its OIDC `sub` to the environment form, the prod deploy trust gained `environment:prod` first (`scripts/bootstrap_aws.sh`; re-run the prod bootstrap before this lands) (#57). The jobs stay thin — `environment:`, `permissions` and one `uses:` per job — with the shared S3 logic in one composite action (`.github/actions/aws-s3`), which the staging and prod S3 targets share through an environment token; the Pages steps are inline in the prod callee. Two constraints shape this and are worth remembering: a job that calls a reusable workflow **cannot carry `environment:`**, so the reviewer gate lives in the callee — and the callees are **local** files, not library reusables, so the gate sits in this repo, one commit from the workflow it guards; and a caller job's `permissions` is a **ceiling** that the callee can only downgrade, so each caller grants the union its callee's jobs need.
- **Release documentation now matches the tag scheme** — `CHANGELOG.md` no longer claims adherence to Semantic Versioning and no longer explains minor/patch/major bumps, because a timestamp cannot express them; it states the scheme the tags actually use (`v<year>.<MMDD>.<HHMM>`, cut at release time, with a breaking change called out in the release notes) and records that a section heading carries the tag **without** its leading `v`. That last part is load-bearing: `scripts/releases_hook.py` builds each timeline link as `v{version}`, so a `v` in the heading would render `vv2026…` targets and defeat the hook's tag-promotion duplicate check — the generator itself needs no change, since its tag pattern already matches the timestamp form. The three atlas release pages stop citing semver.org for the same reason; published sections keep their SemVer headings as history (#92).

### Fixed
- **Modal and lightbox URLs are validated before use — and relative targets resolve against the page again** — the three attribute-driven scripts (`resume-modal`, `cert-modal`, `hero-lightbox`) piped a raw `data-*` value into `link.href` / `window.open` / `iframe.src` / `img.src`. Each now resolves the value through a small helper and accepts only `http:`/`https:`, so `javascript:` or `data:` can no longer reach a sink; the lightbox additionally requires same-origin, because every `data-lightbox-src` is a local asset. `cert-modal` also stops resolving against `window.location.origin`: the credential viewer is a **relative** `../credentials.html?id=…`, so an origin-based base pointed it at the domain root, which 404s on the gh-pages deploy — masked until now only because the root-hosted CloudFront mirror resolves both forms identically. The modal's "open in new tab" target is validated at the sink like the iframe. Clears three `js/xss-through-dom` CodeQL alerts (#86).
- **The URL substitution no longer dies when a placeholder form is absent** — the bare-form pass in the entry above can never match: the build bakes `site_url` **with** its trailing slash, so all 464 occurrences on the artifact are the slash form and the slash pass consumes them first, leaving the bare `grep` to find nothing and exit 1 — which, under the step's `bash -e -o pipefail`, aborted the whole substitution **before** any `::error` was printed, so every site-changing deploy reported a bare `Process completed with exit code 1`. Each of the three passes now ends `|| true`, making an absent form a no-op; a real leftover is still caught, because the guard that asserts no placeholder **host** survives runs immediately after and is what fails the step loudly.

### Security
- **pdf.js upgraded off CVE-2024-4367 — a high-severity remote-code-execution in the vendored viewer** — `docs/assets/js/pdf.min.js` and `pdf.worker.min.js` sat at 3.11.174 (2023), inside the vulnerable `pdfjs-dist <= 4.1.392` range for CVE-2024-4367 (arbitrary JavaScript execution on opening a malicious PDF), and the standalone viewer's unvalidated `?pdf=` parameter plus the complete absence of a CSP made that reachable from a crafted link to our own origin. Both files are now the **6.3.289** builds — chosen over the minimum patch 4.2.67 because the 5.6.83–6.2.107 window carries a second high-severity regression (CVE-2026-16633). pdfjs-dist 4.x and later ship **ESM only**, so this is a module migration: the files keep their `.js` names (a `.mjs` name risks an octet-stream MIME type on the S3/CloudFront plane, which would break module loading there) while carrying ESM content, `pdf-viewer.js` becomes a module that imports the library and derives the worker URL from `import.meta.url`, and it loads from `overrides/main.html` because Material exposes no documented `type: module` mapping for `extra_javascript`. It also leaves `minify.js_files`, since `jsmin` cannot parse ESM. Two v3-to-v6 API changes were needed in the viewer once it actually ran: `getDocument(url)` — the string/URL form was **removed in v4**, so it now takes `{ url }` — and `viewport.convertToViewportRectangle()`, which v6 no longer exposes, so the link-overlay box is derived from two `convertToViewportPoint()` calls; `render()` itself needed no change (#94).
- **The `?pdf=` parameter is now allowlisted** — the standalone viewer accepted any absolute URL and passed it to `getDocument()`, so `/assets/pdf-viewer.html?pdf=https://…` loaded a third-party document into our origin. It now accepts only `pdf/resume.pdf`, `pdf/resume-es.pdf` and `pdf/resume-zh.pdf` (#94).

## [3.3.0] - 2026-09-04

### Added
- **"The Platform Behind This Site" project page** — first entry under Projects (en/es/zh): prose-first case study of the platform (architecture, delivery model, CI/CD, governance, security, real incidents) with GitHub references (#49).
- **Site Atlas — Platform Architecture page** — the four explored diagrams on-site (site delivery, visitor metrics, Terraform control plane, how a change ships), separate from the zoomable Site Structure map (#50, folded into #53).
- **Structure-map rectification** — Site Metrics submenu shows its real shape (default → Visitor Analytics → CloudFront → API → writer/reader → DynamoDB); the AWS metrics backend renders inside its own theme-aware subgraph; Projects gains the new page's node (#49/#50/#53).
- **Release timeline generated from CHANGELOG** — `scripts/releases_hook.py` builds the rows at compile time (no drift); on `v*` tag builds the hook promotes the `[Unreleased]` content into the tag's version so prod shows the just-released release; the Site Atlas landing lists the latest 10, the full archive stays reachable (#49/#50/#53).
- **Branch + tag rulesets as code** — `main` (PR-only, strict, no bypass) and `v*` tag rulesets defined in exportable JSON and applied via `gh api`; enforcement verified and recorded beside the configs (#25/#35, #36/#38, #37/#39, #40/#41).
- **Curated labels + template taxonomy** — five per-surface labels (`ci` · `infra` · `security` · `governance` · `dependencies`), PR template ↔ label mapping, 7-part issue structure documented (#11, #15, #18, #26/#27).

### Changed
- **Docs split into system + implementation views** — root README slimmed to the system view; `.github/workflows/README.md` is the CI/CD implementation reference; `terraform/README.md` audited for accuracy (#23/#28, #24/#34).
- **Check names are the gate names** — CI reports job names (`ci-build`, `checks-<surface>-<tool>`) so rulesets require exactly what runs; per-surface checks self-gate on changed paths (skip-model), skipping and reporting success when untouched (#12, #17).
- **Prod deploy split** — `v*` deploys to pre-prod (AWS mirror) then gated prod (GitHub Pages via the official Pages actions); OIDC trust extended for environment-bearing deploy jobs (#20, #22).
- **Staging content-hash skip** — byte-identical artifacts skip sync + invalidation via marker objects (existence-checked — no extra IAM needed) (#29/#30, #31/#32).
- **Local check driver** — `scripts/check_local.sh`: default runs every surface whose files changed (diff-gated, mirroring CI), `--full` for a whole-repo pass, per-language selection; `check-compose.yaml` services fixed so every local check is runnable and truthful (#52).

### Fixed
- **Local checks were silently checking nothing** — docker-compose interpolated `$f` at parse time (empty filenames) and the trailing `echo ok` masked failures; escaped with `$$f` and made per-file failures fail the service (#52).
- **Broken CJK heading anchor** — zh project page's in-page link pointed at a slug the theme never generated; pinned an explicit `{#delivery-model}` anchor across locales (#49/#50/#53).

### Dependencies
- Bumps: ruff-action v3, mkdocs-git-revision-date-localized-plugin 1.5.4 (#9, #10).

## [3.2.0] - 2026-09-01

### Added
- **Local HTTPS dev server** — one mkcert root CA per machine (`certs/` gitignored); `serve.py` TLS flags; `compose.yaml` cert mount + https-first healthcheck. Per-project certs for `*.mathewmusango.test`.
- GitHub release badge in the repo README (latest release incl. pre-releases).

### Changed
- **Title standardized to "Platform Engineering Manager"** across the site (about tagline en/es/zh + meta description) — previously "…and Infrastructure Leader".
- **Resume PDFs updated** in all three locales (headline: `Senior Platform Engineer · Tech Lead, Platform Engineering`).
- **Deploy workflows deploy on every successful CI build** — the site-changes gate (which only diffed `HEAD~1..HEAD`) is removed.
- CloudFront toggle is **staging-only** (prod has no toggle role).

### Fixed
- **Site bucket SSE reverted to AES256** (`aee25c6`): SSE-KMS (even the AWS-managed key) is **incompatible with CloudFront OAC** — CloudFront can't get `kms:Decrypt`, so a content deploy after the KMS change made the staging site 403 on every object (prod would have hit the same on its next deploy). The state bucket keeps KMS (not OAC-served). Checkov CKV_AWS_145 is satisfied by AES256.
- **Deploys no longer skip on multi-commit batches** (`1bf9bd9`): the deploy gate diffed only `HEAD~1..HEAD`, so a batch whose last commit wasn't a site change never deployed — staging went stale.

## [3.1.1] - 2026-08-28

### Security
- **IAM hardening**: the CI terraform role's IAM is scoped — role/policy management on project resources only; `iam:PassRole` limited to the two Lambda roles with a service condition (privilege-escalation vector closed).
- **S3 encryption**: site + state buckets now use KMS (`aws:kms`, AWS-managed key — zero cost, no CMK).
- **Security headers at the edge**: a CloudFront response-headers policy (nosniff, frame-DENY, referrer, HSTS) is attached to both distributions.
- **TLS 1.2+** pinned explicitly on both CloudFront distributions.
- Static security scanning (Checkov) in CI — every finding is fixed or annotated with the reason (Free-Tier constraint, public-by-design, AWS limitations).

### Changed
- **Terraform static checks** (fmt / validate / tflint / checkov) run in CI on every terraform change.
- **S3-native state locking** (`use_lockfile`) replaces the deprecated DynamoDB lock config.
- **`terraform/ci` state moved to S3** (per-env bucket, `ci/` key) — no more local-only state.
- **CloudFront invalidation**: shared `scripts/invalidate-cloudfront.sh` + manual `invalidate.yml` workflow; deploys invalidate inline after each sync.
- **CI workflow concurrency guard** per environment.

### Fixed
- Reserved concurrency reverted — the account's Lambda concurrency limit (10) makes it impossible (annotated accept).
- Lambda/CloudFront permission gaps in the CI role closed (concurrency + response-headers-policy actions).

## [3.1.0] - 2026-08-28

### Fixed
- **Language switcher on the AWS sites** — the switcher now works on every page: root pages' language links (which carried the gh-pages `/my-portfolio/` base) are rewritten for root-hosted deployment, and subpages' page-relative links pass through unchanged.
- **Directory URLs without a trailing slash** (`/es/about`) now resolve correctly on CloudFront + S3 instead of 404.
- **404 page** — language switcher links and the Home button now point at the current host's root (they were baked to `/my-portfolio/`).

## [3.0.1] - 2026-08-28

### Changed
- **Bootstrap drift guard**: `terraform/ci` now carries a warning that the CI roles/policies only reach AWS when `scripts/bootstrap-aws.sh <env>` is re-run — after any `terraform/ci` change, re-run it for **both** environments (prod's role policy had drifted one run behind and failed the prod apply on `dynamodb:UpdateTimeToLive`).
- **Versioning semantics documented**: tag-and-release policy (site-input deploy gate, MINOR/MAJOR/PATCH meanings) recorded in the project skill + private guide.
- Docs: README + terraform README synced to the current architecture (metrics live on both environments, injected deployment values, single-repo flow).

## [3.0.0] - 2026-08-28

### Added
- **AWS platform (staging + prod)** — the site now runs on real infrastructure: a private S3 bucket behind CloudFront (OAC) serving at `/`, with staging (main pushes) and prod (`v*` tags) environments.
- **Three deploy targets**: staging S3 on `main`, prod S3 + GitHub Pages on `v*` tags — deploys gate on `docs/` / `overrides/` / `mkdocs.yml` changes.
- **Live visitor analytics (both environments)**: CloudFront (geo headers) → API Gateway → Lambda (reader/writer, least-privilege IAM) → DynamoDB (90-day TTL) — the Site Metrics dashboard now shows real data.
- **Free edge origin-gate** (CloudFront Function): only the site may call the metrics API — WAF-equivalent at $0.
- **Localized error pages** (403/404 → `/404.html`, 500 → language-matched page) and **directory-URL resolution** (`/path/` → `/path/index.html`) on CloudFront.

### Changed
- **Terraform value hygiene** — zero static values in code: `project`, `environment`, `aws_region`, `allowed_origin`, and `tags` are injected at runtime (CI secrets / local tfvars); the WAF host is derived from `allowed_origin`.
- **Per-environment least-privilege roles** (terraform vs deploy) and state-based OIDC provider ownership.
- **Language switcher** fixed on all hosts (relative links — dev server, S3, CloudFront).
- **Metrics endpoint per target** — staging and prod each bake their own beacon endpoint at build time.

### Fixed
- 404s on CloudFront + S3 from directory URLs and non-root path layouts.
- Metrics beacon fetch failing with schemeless endpoints — endpoints are now configured with the full `https://` URL.

## [2.5.0] - 2026-08-25

### Added
- **Glossary tooltips**: technical acronyms (AWS, PCI-DSS, CI/CD, LCP, INP, CLS, SBOM, …) now show a hover tooltip with their meaning — site-wide, in all three languages.

### Changed
- **Release Timeline**: now sortable by version (dot-aware ordering) via a self-hosted tablesort, plus a primary "View all releases" button.
- **Home CTAs**: "Contact Me" is a primary button linking to the Contact page, the home buttons gained icons, and the redundant "Connect via LinkedIn" button was removed.
- **Error pages**: the 404 and 500 "Home" / "Contact Me" buttons are now primary with white icons, matching the home page.

### Fixed
- Punctuation: the About languages line and the Projects index descriptions now end with a period in all three languages.

## [2.4.0] - 2026-08-25

### Added
- **Site Structure page** (Site Atlas menu, trilingual): interactive mermaid site-map — self-rendered with the site theme (light/dark aware), node labels localized per language, hover preview cards, clickable nodes that open pages in a new tab, and inline zoom controls.
- **Site Atlas submenu**: the single page split into a landing (intro + The Repository), Release Timeline, and Tags index — a collapsible menu like Home.
- **Mermaid self-hosted** (mermaid@11.17.1) — diagrams render without runtime CDN requests.

### Changed
- **Breadcrumbs**: each tab root shows its own name; the Home crumb appears only for Home-section pages; tab-root duplicates removed (no more "Site Atlas › Site Atlas").
- **Typography**: balanced heading line breaks and no orphaned body words site-wide.
- Site Structure URL moved under `/atlas/structure/` (folder-style, like Tags).

## [2.3.0] - 2026-08-22

### Added
- **Site Metrics dashboard** (trilingual): instrument-panel page with real site facts — stat cards (pages, languages, last updated, automated delivery + SBOM), a page-group bar chart, and "Planned" status cards for visitor analytics, uptime, and performance. Privacy-first: no tracking scripts shipped.
- **Custom breadcrumb**: `Home › … › current page` trail (bold current), localized per language, hidden on the homepage.
- **Site History page** (trilingual) with footer icon links (Site History · Email · LinkedIn · GitHub) and a static og:image share card.
- **`navigation.tracking`**: scroll-spy sidebar with URL hash per section (deep-linkable headings).
- **`navigation.prune`**: pages missing from `nav:` are hidden from the sidebar/tabs but remain reachable by URL.

### Changed
- **Navigation tabs**: now `Home · Site Metrics` with icons; the active tab highlight merges with the tab bar's bottom edge; header band narrowed.
- **Projects**: overview + five category pages, collapsible submenu with the first item open by default, labels localized per language.
- **Footer**: prev/next fix (Skills → Projects, was "Overview"); icons-only links; Material generator badge hidden (`generator: false`).
- es/zh homepage: stale `projects.md` link fixed → `projects/`.

## [2.2.0] - 2026-08-21

### Added
- **i18n folder structure**: pages now live in `docs/en/`, `docs/es/`, `docs/zh/` (was flat `*.es.md`/`*.zh.md` suffix naming) — rendered URLs unchanged.
- **Localized error pages**: `500` page translated per language (`/500/`, `/es/500/`, `/zh/500/`), and the `404` page is JS-localized from the URL prefix (`/es/`, `/zh/`) since it's a single static template.
- **Real issuer logos** for the two Coursera certifications: official Google wordmark and the official CU Boulder interlocking mark (replacing placeholder icons).
- **JS/CSS minification** (`mkdocs-minify-plugin`) alongside HTML — custom scripts listed in `js_files`/`css_files` (already-minified pdf.js excluded).
- **Translation staleness check** in CI: an English page committed after its `es`/`zh` translation fails the build until the translation is updated (git commit timestamps).
- **`site_url` canonical config**: sitemap, canonical links, and hreflang alternates now correct in every build (previously only prod CI injected it; local/test builds emitted a broken `None` sitemap).
- **In-depth documentation**: `MKDOCS.md` (mkdocs.yml reference) and refreshed `README.md`; `DEVOPS.md` updated.

### Changed
- `check_translations.py` now enforces presence **and** staleness (heading drift remains a warning).
- The shared build action only injects `site_url` when the config key is absent.

### Fixed
- `404` page broken rendering (a stray `</script>` corrupted the localization script — replaced the fragile regex with string matching).
- `docs/assets/pdf-viewer.html` now references the minified viewer script.

## [2.1.0] - 2026-08-13

### Added
- **Chinese (简体中文) localization**: the full site is available in Chinese, with the header language switcher now offering English, Español, and 中文.
- **Chinese resume PDF** (`resume-zh.pdf`), wired into the Chinese resume page (viewer, download, new-tab).

## [2.0.0] - 2026-08-13

### Added
- **Full Spanish localization**: the entire site is available in Spanish with a header language switcher (globe icon), per-language navigation, and translated pages (Home, About, Experience, Skills, Projects, Certifications, Resume, Contact).
- **Multilingual resume**: a Spanish resume PDF alongside the English one, with the resume viewer, download, and new-tab actions wired per language.

### Changed
- Content refresh across Home, About, Experience, Skills, Projects, Certifications, and Contact (updated taglines, narratives, and copy; "Eclectics International" naming; refreshed language levels).
- Typography: Space Grotesk headings + Inter body.
- Contact page redesigned with side-by-side cards.
- Resume PDF restyled: neutral headings, standard blue hyperlinks.
- Home hero shows an "Email" label instead of the raw address.

### Fixed
- Spanish asset paths (logos, resume PDF, credential badges) under `/es/`.
- Resume PDF worker path on the Spanish page and the standalone viewer.
- Language-switcher navigation (removed `navigation.instant` for correct per-page switching).

## [1.4.0] - 2026-08-13

### Added
- New "Away from the Keyboard" section on the About page.
- Contact page redesigned with side-by-side Email / LinkedIn cards and refreshed copy.

### Changed
- Typography: Space Grotesk headings + Inter body (replacing Saira Extra Condensed + Muli).
- Home page: refreshed About Me intro, Featured Project, and Connect sections (project stack chips kept).
- About page: updated tagline, subtitle, "In a Nutshell" items, and language levels; streamlined "My Story".
- Experience page: refreshed role descriptions and contributions.
- Certifications: clearer stats line (25 · 23 Credly-verified · AWS ×2 · The Linux Foundation ×21).
- Resume PDF: neutral heading colors, standard blue hyperlinks (no underline), refreshed narrative from the source resume, "Eclectics International" naming, and updated language levels.

## [1.3.0] - 2026-08-10

### Added
- Search: suggest + highlight features and a custom tokenizer separator for technical terms.
- Minified HTML output (`mkdocs-minify-plugin`).
- Copyright footer line.
- Abbreviation tooltips (`abbr` + `content.tooltips`), footnotes, and auto-linking of bare URLs (`pymdownx.magiclink`).

### Changed
- CI/CD: actions bumped to Node 24 majors; site artifact retention set to 7 days; deploy commits authored as `mathewmusango`.
- Repo hygiene: `SECURITY.md`, `.gitattributes`, Dependabot (pip + Actions), issue templates; new `DEVOPS.md` in the source repo.

## [1.2.0] - 2026-08-10

### Changed
- Release workflow now generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt` and attaches it to every GitHub Release alongside `site.zip`.

## [1.1.0] - 2026-08-10

### Added
- Header GitHub repository button (repo icon links to the site repository).
- Page created/updated dates via `mkdocs-git-revision-date-localized` and contributor info via `mkdocs-git-committers-plugin-2`.
- Footer GitHub profile link.

### Changed
- Replaced the blue release-notes footer bar with a plain footer (git dates + GitHub profile link).
- Removed the "Edit this page"/"View source" actions (`edit_uri`, `content.action.edit/view`).
- Pinned all Python dependencies in `requirements.txt` for reproducible builds (`mkdocs-git-revision-date-localized-plugin==1.5.3`, `mkdocs-git-committers-plugin-2==2.5.0`).
- Release workflow now generates release notes from the CHANGELOG section for the tagged version.

## [1.0.0] - 2026-08-09

### Added
- Initial site: personal cloud-resume for Mathew Musango Peter — MkDocs + Material, dark slate theme with teal accents.
- Pages: Home, About, Professional Experience, Technical Expertise, Projects, Certifications, Resume, Contact.
- Containerized workflow with podman (`compose.yaml`): live-reload dev server on port 8000 with a `/health` endpoint.
- Certifications: provider accordions, badge cards, and an in-page credential popup (badge links to the credential).
- Portfolio link (`mathewmusango.github.io/my-portfolio`) added to the resume PDF header (Email | LinkedIn | Portfolio | Nairobi, Kenya).
- CI/CD: GitHub Actions CI (`ci.yml` — strict build validation) on this repo. The public
  `mathewmusango/my-portfolio` repo (production) carries its own CI + deploy workflow, publishing
  the built site to its `gh-pages` branch via GitHub Pages.
- GitHub Actions release workflow (`release.yml`): pushing a `v*` tag builds the site and creates a
  GitHub Release with the site archive attached.

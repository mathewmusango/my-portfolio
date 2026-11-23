# Ruleset: `main` — record

**Status:** 🟢 applied — live on `refs/heads/main` · **Config:** [`main.json`](main.json)

**Purpose.** `main` binds every actor: pull requests only, squash only, fourteen shared-check contexts, no bypass — the checks are the review.

| Field | Value |
| --- | --- |
| Enforcement | `active` |
| Merge methods | `squash` |
| Approvals | none — the required contexts are the review · review threads still resolve |
| Bypass actors | none |
| Required checks | the fourteen contexts below, strict |
| Also | `creation` · `deletion` · `non_fast_forward` · `required_signatures` · `code_scanning` |

## The required contexts

| Context | Comes from |
| --- | --- |
| `build` | `build.yml` — the site build, and the one context that is not a shared leaf |
| `js / syntax` | the `js` caller job |
| `python / ruff` | the `python` caller job |
| `shell / shellcheck` | the `shell` caller job |
| `terraform / fmt` | the `terraform` caller job |
| `terraform / lint` | the `terraform` caller job |
| `terraform / security` | the `terraform` caller job |
| `terraform / validate` | the `terraform` caller job |
| `yaml / actionlint` | the `yaml` caller job |
| `yaml / syntax` | the `yaml` caller job |
| `deps / dependency-review` | the `deps` caller job — reports on pull requests only |
| `docker / hadolint` | the `docker` caller job — hadolint over every Dockerfile |
| `pip-audit / audit` | the `pip-audit` caller job — CVEs in `requirements.txt`, `--audit-level` at pip-audit's default |
| `npm-audit / audit` | the `npm-audit` caller job — CVEs in `package-lock.json`, `--audit-level=high`, dev dependencies included on purpose |

**Why these fourteen.** `build` is this repository's own gate; the rest are what [`checks.yml`](../.github/workflows/checks.yml) and [`security.yml`](../.github/workflows/security.yml) report — shell, js, python, docker, terraform, yaml, dependency review and the two dependency audits. Each shared leaf self-gates on changed files, so a surface with nothing to check skips and still reports success, which is what lets all fourteen be required at once.

**No approval count, and why that is not the weaker gate (2026-11-20).** A solo maintainer cannot approve their own pull request, so `required_approving_review_count: 1` did not add a second opinion — it added a second account, and every merge waited on it. Nothing that judges a change moved: fourteen contexts, an up-to-date branch, signed commits, code scanning, squash-only history, and still an empty bypass list, so a pull request remains the only way onto `main`. `dismiss_stale_reviews_on_push` went with the approval, because at zero there is no review to dismiss. The shape now matches `my-workflows`, the other public repository here.

**Secrets are not a CI context here (2026-10-21).** The library dropped its gitleaks leaf (`my-workflows#24`): GitHub secret scanning with push protection already blocks a credential before the commit lands, and GitGuardian reports on every push, so a third scanner added a required context without adding detection. There is no local secret scan: the two server-side scanners are the gate.

**Remediation windows are enforced, not implied (#230).** The audit gate stops a *new*
high or critical advisory at merge; `CI: Dependency SLA` is the other half — a weekly job
that runs both audits on a schedule — the case the gate cannot see is an advisory published
after a dependency merged. The windows are **critical 7 days · high 30 · moderate 90 · low at
the next dependency refresh**.

**Audit thresholds, written down because the leaf alone does not explain them.** `npm audit` runs `--package-lock-only --audit-level=high` and deliberately **omits** `--omit=dev`: every npm package here is a `devDependency`, but their `dist` bundles are exactly what the browser runs, so `--omit=dev` would audit an empty tree and always pass. `pip-audit` is pinned inside the leaf, because a gate should not change under the repositories it judges. Both match `dependency-review`'s `fail-on-severity: high`, so an advisory with no fix cannot block every pull request.

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/22026993 --input rulesets/main.json
```

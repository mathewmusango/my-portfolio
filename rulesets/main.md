# Ruleset: `main` — record

**Status:** 🟢 applied — live on `refs/heads/main` · **Config:** [`main.json`](main.json)

**Purpose.** `main` binds every actor: pull requests only, one approval, squash or rebase, fourteen shared-check contexts, no bypass.

| Field | Value |
| --- | --- |
| Enforcement | `active` |
| Merge methods | `squash` · `rebase` |
| Approvals | 1 · stale reviews dismissed on push · review threads resolved |
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

**Secrets are not a CI context here (2026-10-21).** The library dropped its gitleaks leaf (`my-workflows#24`): GitHub secret scanning with push protection already blocks a credential before the commit lands, and GitGuardian reports on every push, so a third scanner added a required context without adding detection. The local pre-commit `gitleaks` service ([`containers/checks`](../containers/checks/README.md)) remains the earlier net — it warns while you work, which the server-side scanners cannot.

**Audit thresholds, written down because the leaf alone does not explain them.** `npm audit` runs `--package-lock-only --audit-level=high` and deliberately **omits** `--omit=dev`: every npm package here is a `devDependency`, but their `dist` bundles are exactly what the browser runs, so `--omit=dev` would audit an empty tree and always pass. `pip-audit` is pinned inside the leaf, because a gate should not change under the repositories it judges. Both match `dependency-review`'s `fail-on-severity: high`, so an advisory with no fix cannot block every pull request.

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/22026993 --input rulesets/main.json
```

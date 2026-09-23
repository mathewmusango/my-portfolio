# Ruleset: `main` — record

**Status:** 🟢 applied — live on `refs/heads/main` · **Config:** [`main.json`](main.json)

**Purpose.** `main` binds every actor: pull requests only, one approval, squash or rebase, twelve shared-check contexts, no bypass.

| Field | Value |
| --- | --- |
| Enforcement | `active` |
| Merge methods | `squash` · `rebase` |
| Approvals | 1 · stale reviews dismissed on push · review threads resolved |
| Required checks | the twelve contexts below, strict |
| Bypass actors | none |
| Also | `creation` · `deletion` · `non_fast_forward` · `required_signatures` · `code_scanning` |

## The required contexts

| Context | Comes from |
| --- | --- |
| `build` | `ci.yml` — the site build, and the one context that is not a shared leaf |
| `js / syntax` | the `js` caller job |
| `python / ruff` | the `python` caller job |
| `shell / shellcheck` | the `shell` caller job |
| `terraform / fmt` | the `terraform` caller job |
| `terraform / lint` | the `terraform` caller job |
| `terraform / security` | the `terraform` caller job |
| `terraform / validate` | the `terraform` caller job |
| `yaml / actionlint` | the `yaml` caller job |
| `yaml / syntax` | the `yaml` caller job |
| `secrets / gitleaks` | the `secrets` caller job |
| `deps / dependency-review` | the `deps` caller job — reports on pull requests only |

**Why these twelve.** `build` is this repository's own gate; the rest are what [`checks.yml`](../.github/workflows/checks.yml) reports for its file types — shell, js, python, terraform, yaml, secrets and dependency review. Each shared leaf self-gates on changed files, so a surface with nothing to check skips and still reports success, which is what lets all twelve be required at once.

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/22026993 --input rulesets/main.json
```

**Verified.** Read back with `gh api repos/mathewmusango/my-portfolio/rulesets` on 2026-09-23: two rulesets, `branch: main` with twelve required contexts and no bypass actors, and `tag: v*`. A direct push to `main` was rejected on 2026-09-04 for both the admin and the write collaborator — *"Changes must be made through a pull request"* — and the required set has grown from 10 to 12 since, when the shared leaves were added.

**Change flow.** Edit the JSON (export format) → apply it → update this record in the same pull request.

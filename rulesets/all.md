# Ruleset: `branches: all` — record

**Status:** 🟢 applied — live on every branch · **Config:** [`all.json`](all.json)

**Purpose.** The branch-name gate — every branch targeted, the allowed names below excluded, `creation` as the only rule. Anything not excluded is refused at the push.

| Field | Value |
| --- | --- |
| Target | every branch (`~ALL`), minus the excludes below |
| Required checks | none — this gates creation, not merging |
| Bypass actors | none, so the name rules bind everyone, owner included |
| Rules | `creation` only |

## The allowed names

The excludes *are* the allow-list:

| Excluded, i.e. allowed | Notes |
| --- | --- |
| `refs/heads/main` | the default branch |
| `refs/heads/dependabot/*` · `/*/*` · `/*/*/*` · `/*/*/*/*` | four levels, so a monorepo branch such as `dependabot/npm_and_yarn/packages/app/foo-1.0.0` is not refused |
| `refs/heads/feature/*` · `fix/*` · `docs/*` · `ci/*` · `infra/*` · `security/*` · `governance/*` · `deps/*` · `content/*` | one path segment each |

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets/24025480

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/24025480 --input rulesets/all.json
```

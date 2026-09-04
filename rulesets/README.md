# Rulesets — branch & tag protection as code

Two repository rulesets, defined as code (`main.json`, `tags.json` — GitHub **export/import
format**) and applied via `gh api` (commands live in the project's private notes). Enforcement
test records sit beside the configs (`main.md`, `tags.md`).

## `main` — `refs/heads/main` (strict for everyone)

| Rule | Effect |
| --- | --- |
| `pull_request` | No direct pushes — every change via PR: 1 approval, squash/rebase only, stale reviews dismissed, threads resolved |
| `required_status_checks` | All 10 job-name checks, strict (branch up to date before merge) |
| `creation` | Only bypass actors may (re)create the branch |
| `deletion` · `non_fast_forward` | Can't delete `main` or force-push it |

**Bypass: none — owner included.** Verified: direct pushes are rejected even for the admin.

## `v*` tags — `refs/tags/v*` (release tags)

| Rule | Effect |
| --- | --- |
| `creation` | Tags minted only by bypass actors (the maintainer) |
| `required_status_checks` | Tag only commits with green `ci-build` |
| `deletion` · `non_fast_forward` | Release history is immutable |

**Bypass: repo admin** — required so the maintainer can cut releases; by design this also
bypasses the `ci-build` check for the admin, so the human **tag-guard** (tag `main` tip after
green CI, CHANGELOG updated) is the admin-side gate.

## Enforcement model

Rulesets bind everyone except their listed bypass actors — enforcement is **push-time**, and a
rejected push fires nothing (safe to test). `main` grants no bypass; `v*` grants admin only.

## Change flow

Edit the JSON (export format) → apply (`gh api --method PUT …/rulesets/<id> --input <file>`) →
update the sibling `*.md` verification record in the same PR (bump **Last verified**).

Verification records: [`main.md`](main.md) · [`tags.md`](tags.md)

# Ruleset: `v*` tags — record

**Status:** 🟢 applied — live on `refs/tags/v*` · **Config:** [`tags.json`](tags.json)

**Purpose.** Release tags are minted only by the maintainer, and only on a commit with a green `build`. Every other actor is bound by both rules.

| Field | Value |
| --- | --- |
| Enforcement | `active` |
| Rules | `creation` · `required_status_checks` (`build`) · `deletion` · `non_fast_forward` |
| Bypass actors | repository admin — `creation` admits only its bypass actors, so an empty list would admit nobody and no release could be cut |

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/22227856 --input rulesets/tags.json
```

**Verified.** Read back with `gh api repos/mathewmusango/my-portfolio/rulesets` on 2026-09-23: `tag: v*`, `active`, four rules, admin-only bypass. A tag push as the write collaborator was rejected on 2026-09-04 — *"Cannot create ref due to creations being restricted"* — while an admin push is accepted by design, which is why the admin-side gate is the tag-guard process rather than the ruleset.

**Change flow.** Edit the JSON (export format) → apply it → update this record in the same pull request.

# Ruleset: `v*` tags — record

**Status:** 🟢 applied — live on `refs/tags/v*` · **Config:** [`tags.json`](tags.json)

**Purpose.** Release tags are immutable, and are accepted only against a commit whose `build` passed.

| Field | Value |
| --- | --- |
| Rules | `required_status_checks` (`build`, strict) · `deletion` · `non_fast_forward` · `update` |
| Bypass actors | none |

**No `creation` rule, and that is load-bearing.** With no bypass actor, `creation` refuses every tag push — *"Cannot create ref due to creations being restricted"*, proved on `my-workflows` on 2026-09-25 — so while this ruleset carried it, **no release could be tagged**. It was dropped on 2026-09-25; the next release tag is the live test of the fix.

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets/22227856

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/22227856 --input rulesets/tags.json
```

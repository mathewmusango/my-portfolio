# Ruleset: `tag: v*` — record

**Status:** 🟢 applied — live on `refs/tags/v*` · **Config:** [`tags.json`](tags.json)

**Purpose.** Release tags are immutable, are accepted only against a commit whose `build` passed, and require the tagged commit to be signed.

| Field | Value |
| --- | --- |
| Target | `refs/tags/v*` |
| Required checks | `build`, strict |
| Bypass actors | none |
| Rules | `deletion` · `non_fast_forward` · `update` · `required_signatures` |

**Signed commits (2026-10-05).** `required_signatures` checks the tagged *commit's* verified signature, not the tag object's, so a tag cut at a `main` tip (already signed) is unaffected; it closes the gap for any tag that is not.

**No `creation` rule, and that is load-bearing.** With no bypass actor, `creation` refuses every tag push — *"Cannot create ref due to creations being restricted"*, proved on `my-workflows` on 2026-09-25 — so while this ruleset carried it, **no release could be tagged**. It was dropped on 2026-09-25; the next release tag is the live test of the fix.

## Applying

```sh
# Read it back — this is how the file here was produced
gh api repos/mathewmusango/my-portfolio/rulesets/22227856

# Replace it in place. Strip id, source and source_type from the body first:
# they are read-only, and the id lives in the URL.
gh api --method PUT repos/mathewmusango/my-portfolio/rulesets/22227856 --input rulesets/tags.json
```

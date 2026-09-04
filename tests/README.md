# Tests & Verification Records

Records are classified by **category → target**; each file follows one template (**Last
verified · Status · Relates to · Config/Target** + **Purpose · Method · Result · Lesson**) and is
updated in the PR that changes the behavior. Steps/identity mechanics stay private.

| Category | Target | Rules / behavior covered | Status |
| --- | --- | --- | --- |
| Rulesets | [`main`](rulesets/main.md) | PR-only · 1 approval · squash/rebase · 10 checks · no creation / deletion / force-push · no bypass | 🟢 verified |
| Rulesets | [`v*` tags](rulesets/v.md) | creation = maintainer only · `ci-build` required · no deletion / force-move · admin bypass | 🟢 verified |

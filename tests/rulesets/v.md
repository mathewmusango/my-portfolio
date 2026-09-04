# Ruleset: `v*` tags — verification

**Last verified:** 2026-09-04 · **Status:** 🟢 verified · **Relates to:** #25 · **Config:** [`rulesets/tags.json`](../rulesets/tags.json)

**Purpose.** `v*` tags are minted only by the maintainer (admin bypass) and only on commits with
green `ci-build`; everyone else is bound by both rules.

**Method.** `v*` tag push attempts as the write collaborator (rejected, side-effect-free) and as
admin (accepted — fires the pipeline; exercised once, runs cancelled, cleaned up).

**Result.**

| Actor | Outcome |
| --- | --- |
| collaborator (`kizingainc`) | 🔴 rejected — "Cannot create ref due to creations being restricted" + "Required status check 'ci-build' is expected" |
| admin (`mathewmusango`) | 🟢 accepted (bypass notice) — by design for releases |

**Lesson.** Enforcement binds non-bypass actors only — a negative admin test is impossible by
design; the tag-guard process is the admin-side gate.

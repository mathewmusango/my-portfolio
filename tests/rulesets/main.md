# Ruleset: `main` — verification

**Last verified:** 2026-09-04 · **Status:** 🟢 verified · **Relates to:** #25, #37 · **Config:** [`rulesets/main.json`](../rulesets/main.json)

**Purpose.** `main` binds every actor — PR-only, 1 approval, squash/rebase, all 10 checks, zero
bypass.

**Method.** Direct-push attempts of a scratch commit to `refs/heads/main`, as admin and as the
write collaborator. Rejected pushes are side-effect-free.

**Result.**

| Actor | Outcome |
| --- | --- |
| admin (`mathewmusango`) | 🔴 rejected — "Changes must be made through a pull request" + "10 of 10 required status checks are expected" |
| collaborator (`kizingainc`) | 🔴 rejected — same |

Remote unchanged afterwards.

**Lesson.** The only path to `main` is PR → approval → squash — the owner included.

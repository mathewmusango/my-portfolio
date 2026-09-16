# Ruleset: `main` — verification

**Last verified:** 2026-09-04 · **Status:** 🟢 verified · **Relates to:** #25, #37 · **Config:** [`main.json`](main.json)

**Purpose.** `main` binds every actor — PR-only, 1 approval, squash/rebase, all 12 checks, zero
bypass.

**Method.** Direct-push attempts of a scratch commit to `refs/heads/main`, as admin and as the
write collaborator. Rejected pushes are side-effect-free.

**Result.**

| Actor | Outcome |
| --- | --- |
| admin (`mathewmusango`) | 🔴 rejected — "Changes must be made through a pull request" + "10 of 10 required status checks are expected" |
| collaborator (`kizingainc`) | 🔴 rejected — same |

Remote unchanged afterwards.

**Set growth (2026-09-16, not re-verified by a push attempt).** The required set went from 10 to
12 when the shared-check leaves were added: `build` plus `js / syntax`, `python / ruff`,
`shell / shellcheck`, `terraform / {fmt,validate,lint,security}`, `yaml / {syntax,actionlint}`,
`secrets / gitleaks` and `deps / dependency-review`. The rejection text above quotes the
2026-09-04 set, so a fresh attempt would now read "12 of 12 required status checks are
expected".

**Lesson.** The only path to `main` is PR → approval → squash — the owner included.

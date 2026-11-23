# Contributing

This repository is a static portfolio site, plus the Terraform that provisions the
infrastructure it runs on and the CI that deploys it.

It is currently maintained by one person and keeps no community. The process below is still
the one every change goes through — the maintainer's own included.

## How a change becomes a merge

1. **An issue first.** What it solves, the proposed solution, the alternatives considered and
   the scope. A pull request without one is closed rather than reviewed, and one issue maps to
   one pull request, not five.
2. **A branch named for it.** `feature/`, `fix/`, `docs/`, `ci/`, `infra/`, `security/`,
   `governance/`, `deps/` or `content/`, then the change. The ruleset refuses any other name
   before the branch exists on the remote, so a badly named branch costs nothing but a rename.
3. **A pull request that closes the issue** — `Closes #N` in the body, and the same label on
   both. The pull request is the only way onto `main`; nothing is pushed to it directly, by
   anyone.
4. **Green checks, then a squash.** `main` requires fourteen contexts on a branch that is up to
   date with it, and a signed commit. It does **not** require an approving review: a solo
   maintainer cannot approve their own pull request, so the ruleset asks for none, and the
   checks are the review. The merge is a squash — one commit per change, on a linear history —
   and the branch goes with it.

The ruleset itself, including why each context is required and how it is thresholded, is
[`rulesets/main.md`](rulesets/main.md). The branch-name gate is
[`rulesets/all.md`](rulesets/all.md).

## What the checks do with a pull request from a fork

The same fourteen contexts run, against a read-only token: the shared check leaves are reusable
workflows, the build runs on GitHub's runners, and none of the repository's secrets are
available to them. Secret scanning with push protection and GitGuardian report alongside, and a
red check is a refusal like any other.

## Before you push

- **No secrets, no state, no keys.** GitHub secret scanning runs with push protection, so a
  credential is refused before it lands; GitGuardian reports on every push.
- **A page change lands in three languages.** The site is written in `docs/en`, `docs/es` and
  `docs/zh`; a change to one that skips the other two is incomplete, not smaller.
- **The pull request is where a change is checked.** The same surfaces run there, one
  workflow per group, and a surface with no matching files reports success without running.

## Reporting rather than changing

Security issues go to [`SECURITY.md`](SECURITY.md), not to an issue — private reporting is open
on this repository. Everything else is an issue.

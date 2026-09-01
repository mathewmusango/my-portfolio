# Contributing

> **Note:** this is a **personal project developed in the open** — the
> OSS-style process below (branch protection, PRs, checks, releases, CoC) is a
> deliberate *practice*, not a community project. Expect the maintainer's own
> changes to dominate; external contributions are welcome but the process is
> primarily how the maintainer works with themselves.

Thanks for taking the time to contribute! This project follows standard
open-source practices — even the maintainer's own changes go through pull
requests.

## Ground rules

- **`main` is protected** — no direct pushes, no force pushes, no deletions.
  Every change lands via a pull request.
- All PRs must pass the required checks (CI + the per-language checks) before
  merging.
- Follow the existing conventions: page-scoped changes, per-locale translation
  rules (English first, then `es`/`zh`), teal `#00897b` theme.

## Workflow

1. **Branch** — create a feature branch from the latest `main`:
   `git checkout -b <type>/<short-description>` (e.g. `fix/resume-link`,
   `feat/metrics-chart`, `docs/readme-badges`, `ci/dependabot`).
2. **Commit** — small, focused commits with conventional messages:
   `feat:` · `fix:` · `docs:` · `chore:` · `ci:` · `style:` · `refactor:`.
   Reference the issue when one exists (`fix #12`).
3. **Push + open a pull request** — the PR template guides you. Checks run
   automatically on the PR; fix anything red.
4. **Review & merge** — PRs require **one approval** before merging (the
   maintainer reviews with a separate GitHub account to keep the process
   honest). Squash-merge to keep `main` history clean.

## Checks

Each surface is linted by its own workflow; checks run on PRs (path-filtered
— only the workflows matching your changed files run) and via manual dispatch.
**Branch protection requires checks by job name** (not workflow name) — the
names below are what you'll see on PRs:

| Required check | Covers |
| --- | --- |
| `ci-build` | strict `mkdocs build`, pip-audit, internal link + translation checks |
| `checks-python-ruff` | `ruff` on `terraform/lambda/**` + `scripts/*.py` |
| `checks-shell-shellcheck` | `shellcheck` on `scripts/*.sh` |
| `checks-js-node-check` | JS syntax check on `docs/**/*.js` |
| `checks-terraform-fmt` | `terraform fmt -check` |
| `checks-terraform-validate` | `terraform validate` (all three roots) |
| `checks-terraform-lint` | TFLint |
| `checks-terraform-security` | Checkov security scan |
| `checks-yaml-syntax` | YAML parse of every yml/yaml |
| `checks-yaml-actionlint` | actionlint on workflows + compose/mkdocs YAML |

## Translations

Content is maintained **English first** — open the English change, then add the
`.es.md` / `.zh.md` translations in the same PR (never all three at once
without the English base). CI's translation check enforces parity.

## Releases

See [CHANGELOG.md](CHANGELOG.md) for the release policy. Releases are cut by
tagging `main` — the tag creates the GitHub Release + SBOM and deploys prod
(gh-pages + CloudFront). Tag only when the live site changes.

## Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) for the disclosure
process — please don't open a public issue for security problems.

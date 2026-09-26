# .github

| File | What it is |
| --- | --- |
| [`actions/build-site/`](actions/build-site/action.yml) | the composite `ci.yml` runs — pip cache, `mkdocs build --strict`, translation parity, `pip-audit`, link check, CSS sanity |
| [`actions/aws-s3/`](actions/aws-s3/action.yml) | the deploy composite — download the artifact, assume the deploy role (OIDC), `aws s3 sync`, then the invalidate role for an inline `/*` purge |
| [`CODEOWNERS`](CODEOWNERS) | `* @mathewmusango` — one line, no exceptions |
| [`dependabot.yml`](dependabot.yml) | one entry per manifest: `pip`, `npm`, `terraform` ×3 and `github-actions` |
| [`ISSUE_TEMPLATE/`](ISSUE_TEMPLATE) | the bug-report, feature-request and chore forms, plus their chooser config |
| [`PULL_REQUEST_TEMPLATE.md`](PULL_REQUEST_TEMPLATE.md) | the pull-request checklist |
| [`workflows/`](workflows/README.md) | every workflow, documented beside them |

## Security surfaces

Where each one acts, and whether it can hold back a merge.

| Surface | Where it acts | Blocks a merge? |
| --- | --- | --- |
| Push protection | `git push`, before the pull request exists | **Yes** — the push is refused |
| Native secret scanning | the whole repository, every branch | No — an alert in the Security tab |
| `secrets / gitleaks` | CI, on the pull request — a required context | **Yes** |
| `gitguardian / gitguardian` | CI, on the pull request — its own caller job and the `GITGUARDIAN_API_KEY` secret | No — it reports; it is not a required context |
| `terraform / security` | CI, on the pull request — Checkov, via `security.yml` | No — `soft_fail: true` while the audit backlog lands |
| `deps / dependency-review` | CI, on the pull-request diff — a required context | **Yes** |
| `Analyze (…)` + the ruleset's `code_scanning` rule | the pull request's analysis, and the `main`/weekly baseline | **Yes** — on alerts at `high_or_higher` |
| Dependabot alerts | the dependency graph, from the default branch | No — it answers with a patch pull request |

## Settings that are not files

Set by hand; a clone or a pull carries none of them.

| Setting | State |
| --- | --- |
| Rulesets | **applied** — three: `branch: main` (12 required contexts), `branches: all` (the branch-name gate) and `tag: v*` — all with no bypass. Recorded in [`../rulesets/`](../rulesets/README.md) |
| Labels | `dependencies` · `github-actions` — the two `dependabot.yml` names, both present. Dependabot silently ignores a label the repository does not have |
| Push protection | on |
| Secret scanning | on |
| Private vulnerability reporting | on — hence the **Security → Report a vulnerability** route in [`SECURITY.md`](../SECURITY.md) |
| Non-provider secret patterns | **off** — free here, and the only cover for a secret no provider pattern matches |
| Secret validity checks | **off** — free here, and it separates a live secret from a dead one |

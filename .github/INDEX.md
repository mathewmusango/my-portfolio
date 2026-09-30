# .github

| File | What it is |
| --- | --- |
| [`actions/build-site/`](actions/build-site/action.yml) | the composite `build.yml` runs — pip cache, `mkdocs build --strict`, translation parity, `pip-audit`, link check, CSS sanity |
| [`actions/aws-s3/`](actions/aws-s3/action.yml) | the deploy composite — download the artifact, assume the deploy role (OIDC), `aws s3 sync`, then the invalidate role for an inline `/*` purge |
| [`CODEOWNERS`](CODEOWNERS) | `* @mathewmusango` — one line, no exceptions |
| [`dependabot.yml`](dependabot.yml) | one entry per manifest: `pip`, `npm`, `terraform` ×3 and `github-actions` |
| [`ISSUE_TEMPLATE/`](ISSUE_TEMPLATE/) | the bug-report, feature-request and chore forms, plus their chooser config |
| [`PULL_REQUEST_TEMPLATE.md`](PULL_REQUEST_TEMPLATE.md) | the pull-request checklist |
| [`workflows/`](workflows/) | every workflow — CI, checks, deploy, release and infra |

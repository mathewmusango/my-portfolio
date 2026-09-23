# rulesets — branch protection as code

A ruleset is a repository setting, not a file, so nothing here arrives by clone or pull — the JSON is read back and written in place with `gh api`.

| File | What it is |
| --- | --- |
| [`main.json`](main.json) | the live ruleset on `refs/heads/main`, in GitHub's export/import format |
| [`main.md`](main.md) | the record beside it — what it requires, how it was applied, how it was verified |
| [`tags.json`](tags.json) | the live ruleset on `refs/tags/v*`, in the same format |
| [`tags.md`](tags.md) | the record beside it |

Two rulesets: `main` binds every actor, and `v*` admits the maintainer so a release can be cut.

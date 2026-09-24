# containers/checks (compose services)

One compose service per check surface, each pinned to the tool image its CI counterpart uses and running the **same command**. The point is parity: a green container here means the same thing as a green CI job.

Declared here, driven by [`scripts/checks/local.sh`](../../scripts/checks/README.md) — the preferred entry point:

```sh
scripts/checks/local.sh shell        # diff-gated, the normal way
```

Raw compose, for running one service by hand:

```sh
podman-compose -f containers/checks/compose.yml run --rm shell
```

## Services

| Service | Image | Runs |
| --- | --- | --- |
| `shell` | `koalaman/shellcheck-alpine` | `shellcheck -S warning` over `*.sh` + `.githooks/` |
| `python` | `astral-sh/ruff` | `ruff check . --no-cache` — the CI action's own command |
| `yaml` | `rhysd/actionlint` | `actionlint -no-color` over the workflows |
| `yaml-syntax` | `ruby:alpine` | `ruby -ryaml` over every `*.yml` / `*.yaml` |
| `js` | `node:alpine` | `node --check` over every `*.js` |
| `terraform-fmt` | `hashicorp/terraform` 1.15.9 | `terraform fmt -check -recursive -diff terraform/` |
| `terraform-validate` | `hashicorp/terraform` 1.15.9 | `init -backend=false -lockfile=readonly` then `validate`, on both roots |
| `terraform-lint` | `terraform-linters/tflint` | `tflint --init`, then recursive on `terraform/` and `terraform/ci`, both against the root `.tflint.hcl` |
| `terraform-security` | `bridgecrewio/checkov` 3.3.15 | `checkov -d terraform --framework terraform --quiet --soft-fail` |

`secrets` and `deps` have no service on purpose: `gitleaks` and `dependency-review` are CI-only surfaces, the second because it reads a pull-request diff.

## Notes

- The repo root is mounted at `/repo` **read-only** — no check can modify the tree. `site/` and `.git` are pruned from every scan, and the scans are extension-wide across the whole repo, so a new file in a new location is never missed.
- Images carry mutable `latest` tags on purpose (they track whatever CI uses); the first run pulls them. `yaml` uses the docker.io mirror because ghcr.io answered HTTP 403 for the actionlint image on this machine.
- Entrypoints differ per image, which is why the commands are shaped the way they are: `ruff`, `actionlint`, `terraform` and `tflint` run the tool directly (args only), `checkov`'s `/entrypoint.sh` already execs `checkov` (also args only), and the alpine images need an explicit `sh -c`.
- `python` passes `--no-cache` because the mount is read-only and ruff would otherwise try to write `.ruff_cache/` into it.
- `terraform-validate` sets `TF_DATA_DIR` per root, so `init` writes its working directory outside the read-only mount, and `-lockfile=readonly` uses the committed lockfiles. Child modules are validated **through the root that calls them** — `init` resolves and compiles them — so there is no per-module pass and no module lockfile to keep in step. `terraform-lint` runs `--init` at the repo root, where `.tflint.hcl` auto-loads, and its plugin cache lands under `$HOME` inside the container.
- `terraform-security` runs `--quiet --soft-fail`, so Checkov findings are **informational** until the audit backlog is cleared.
- Needs podman and `podman-compose` on the host. The GitHub workflows stay the authoritative gate.

> [!WARNING]
> Compose interpolates `$VAR` from the host environment at parse time, so a shell variable inside `command:` must be written `$$`. Getting this wrong empties the loop variables and **silently skips every file**.

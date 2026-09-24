# scripts (repo tooling)

What the repository runs on a developer's machine: the dev container's lifecycle, the server it runs, two MkDocs build hooks, the AWS bootstrap, and the local check driver.

## `dev.sh` — the dev container

[`dev.sh`](dev.sh) drives the MkDocs dev container declared in [`containers/site/`](../containers/site/README.md).

```sh
scripts/dev.sh build      # build the image from containers/site/Dockerfile
scripts/dev.sh start      # start the container, without building
scripts/dev.sh restart    # recreate the container from the compose file
scripts/dev.sh stop       # stop the container
```

- **`build` is the only verb that builds.** `start` and `restart` pass `--no-build`, so starting never triggers a build, and a machine whose build is broken can still run an image it already has.
- **`restart` recreates rather than restarts.** The source is bind-mounted and reloads live, so the reason to restart is a *compose* change — recreating is what applies it. For a plain restart, `stop` then `start`.
- **It resolves the repository for the git-backed plugins.** `compose.yaml` defaults `PORTFOLIO_GIT_DIR` to `../../.git`, which is right in a normal clone but wrong in a linked worktree, where `.git` is a file pointing at the real directory; mounted as-is, the plugins find no repository. The script exports `git rev-parse --git-common-dir` when `PORTFOLIO_GIT_DIR` is unset, so both layouts work unchanged.

## Files

- [`dev.sh`](dev.sh) — the dev container lifecycle driver
- [`serve.py`](serve.py) — the HTTPS-capable MkDocs dev server the container runs, with `/health`
- [`bootstrap_aws.sh`](bootstrap_aws.sh) — one-command AWS bootstrap per environment: OIDC role, state bucket, lock table, deploy policies
- [`site_metrics_hook.py`](site_metrics_hook.py) — MkDocs build hook filling the Site Metrics facts
- [`releases_hook.py`](releases_hook.py) — MkDocs build hook generating the release rows from `CHANGELOG.md`
- [`checks/`](checks/README.md) — the local check driver, mirroring CI

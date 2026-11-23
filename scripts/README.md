# scripts (repo tooling)

What the repository runs on a developer's machine: the dev container's lifecycle, the server it runs, three MkDocs build hooks, the AWS bootstrap, and the local check driver.

## `dev.sh` — the dev container

[`dev.sh`](dev.sh) drives the MkDocs dev container declared in the root [`compose.yaml`](../compose.yaml) and built from the root [`Dockerfile`](../Dockerfile).

```sh
scripts/dev.sh build      # build the image from the root Dockerfile
scripts/dev.sh start      # start the container, without building
scripts/dev.sh restart    # recreate the container from the compose file
scripts/dev.sh stop       # stop the container
```

- **`build` is the only verb that builds.** `start` and `restart` pass `--no-build`, so starting never triggers a build, and a machine whose build is broken can still run an image it already has.
- **`restart` recreates rather than restarts.** The source is bind-mounted and reloads live, so the reason to restart is a *compose* change — recreating is what applies it. For a plain restart, `stop` then `start`.
- **It resolves the repository for the git-backed plugins.** `compose.yaml` defaults `PORTFOLIO_GIT_DIR` to `.git`, which is right in a normal clone but wrong in a linked worktree, where `.git` is a file pointing at the real directory; mounted as-is, the plugins find no repository. The script exports `git rev-parse --git-common-dir` when `PORTFOLIO_GIT_DIR` is unset, so both layouts work unchanged. A relative value is resolved from the repository root — the folder the compose file sits in.

## The dev image

- **One image and one service.** `name: my-portfolio` in the compose file pins the project, and with it the image name `localhost/my-portfolio_mkdocs`; left to podman-compose it would follow the invocation directory.
- **Python 3.12 slim plus git**, because the revision-date plugin reads the repository. Live reload: the source is bind-mounted over the image's `/app`. `serve.py` serves `0.0.0.0:8000` with TLS from `certs/portfolio.pem` (gitignored), which is why the healthcheck tries https before http.
- **`stop_signal: SIGINT`** — the container's PID 1 is `serve.py`, and the kernel drops a signal that would take its default action for PID 1. Python handles SIGINT but not SIGTERM, so the stock signal made every stop wait out the ten-second grace period and end in a kill.
- **The ignore file is the root [`.dockerignore`](../.dockerignore).** The build context is the repository root, so the rules live there: `scripts/` is pruned because the compose file bind-mounts it at runtime, with `!scripts/hooks/` re-included for the `vendor.json` map the `js` stage reads. The exclusion is written `scripts/*` rather than `scripts/` — dockerignore cannot re-include a directory that is itself excluded.
- **The dependency installs are cached, and the layers are ordered around them.** `npm ci` and `pip install` run under buildah's `--mount=type=cache`, so re-executing either step downloads nothing and no cache enters a layer; the pip layer sits **before** the `node_modules` copy, so an npm bump does not reinstall Python. `npm ci --no-audit --no-fund` and `pip install --no-compile` are consistent with the image's `PYTHONDONTWRITEBYTECODE=1`.
- **Only the bundles the site serves are baked.** The `js` stage copies them out of `node_modules` using the same [`hooks/vendor.json`](hooks/vendor.json) map the MkDocs hook reads, then deletes the tree in that same `RUN` — so the install never enters a layer, and the image carries five JavaScript files instead of a full dependency tree.

`certs/` is local and gitignored — per-project mkcert certificates for `*.mathewmusango.test`. The compose service passes their paths, so the dev server needs them present.

## Files

- [`dev.sh`](dev.sh) — the dev container lifecycle driver
- [`serve.py`](serve.py) — the HTTPS-capable MkDocs dev server the container runs, with `/health`
- [`bootstraps/aws.sh`](bootstraps/aws.sh) — one-command AWS bootstrap per environment: OIDC role, state bucket, lock table, deploy policies
- [`hooks/`](hooks/) — the MkDocs build hooks `mkdocs.yml` loads: [`site_metrics.py`](hooks/site_metrics.py) fills the Site Metrics facts, [`releases.py`](hooks/releases.py) generates the release rows from `CHANGELOG.md`, and [`vendor.py`](hooks/vendor.py) copies the minified JavaScript bundles from `node_modules` into the site. `vendor.py` reads [`vendor.json`](hooks/vendor.json), the source→destination map the dev image also uses to copy just those bundles out of `node_modules`
- [`links.py`](links.py), [`translations.py`](translations.py), [`browser.py`](browser.py), [`actions.py`](actions.py) — the check scripts the workflows run; see **The check scripts** below

## Local setup

Once per machine, before the first `build`:

```sh
mkcert -install                                  # trust the local root CA
mkdir -p certs
mkcert -cert-file certs/portfolio.pem -key-file certs/portfolio-key.pem \
  portfolio.mathewmusango.test localhost 127.0.0.1
echo "127.0.0.1 portfolio.mathewmusango.test" | sudo tee -a /etc/hosts
```

`serve.py` falls back to plain HTTP with a warning if the certificates are missing, so
the site still serves — the browser just complains.

## The check scripts

The checks live in the workflows. Nothing runs them on a developer's machine and no git hook is
installed.

| Script | Runs in | What it checks |
| --- | --- | --- |
| [`links.py`](links.py) | `build-site`, inside `CI: Build` | every internal link in the built site resolves |
| [`translations.py`](translations.py) | `build-site`, inside `CI: Build` | the en / es / zh pages keep the same headings and nav |
| [`browser.py`](browser.py) | `build`, inside `CI: Build` | the viewer pages still render, in headless Firefox |
| [`actions.py`](actions.py) | `build`, inside `CI: Build` | a composite's `run:` body executes under the runner's flags — `if:` evaluated against step outputs, a stub `aws` on `PATH` — and a job using a local action checks out first |

The dependency audits belong to `CI: Security`, and `dependency-review` stays CI-only because its
input is a pull-request diff. GitHub secret scanning runs with push protection, so a credential is
refused before it lands.

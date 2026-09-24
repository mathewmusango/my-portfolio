# containers/site (the MkDocs dev image)

One image and one compose service: the site's live-reload dev server — [`Dockerfile`](Dockerfile) built by [`compose.yaml`](compose.yaml). [`scripts/dev.sh`](../../scripts/README.md) drives the four steps:

```sh
scripts/dev.sh build
scripts/dev.sh start
```

Raw compose, for driving it by hand — the gitdir is handed over absolutely, because a relative `PORTFOLIO_GIT_DIR` is resolved from **this** folder, not the repository root:

```sh
PORTFOLIO_GIT_DIR="$(git rev-parse --path-format=absolute --git-common-dir)" \
  podman-compose -f containers/site/compose.yaml build
PORTFOLIO_GIT_DIR="$(git rev-parse --path-format=absolute --git-common-dir)" \
  podman-compose -f containers/site/compose.yaml up -d --no-build
```

> [!WARNING]
> A relative `PORTFOLIO_GIT_DIR` that was written for the repository root now points below this folder — `../.git/modules/<name>` resolves to `containers/.git/modules/<name>`. Podman **creates that empty directory**, the container starts happily with an empty `/app/.git`, and the git-backed plugins quietly fall back: the site serves, minus its revision dates and committers. Nothing errors.

## What it is

- **The build context is the repository root, not this folder.** The image `COPY`s `requirements.txt`, `mkdocs.yml`, `docs/` and `overrides/` from the context, which is why `compose.yaml` declares `context: ../..` and every bind mount is written `../../`.
- **`name: my-portfolio` pins the compose project, and with it the image name** — `localhost/my-portfolio_mkdocs`. Left to podman-compose the project would be this folder's own name, so the same image would be built and looked for under a different name depending on where the command ran.
- **Python 3.12 slim plus git**, because the revision-date plugin reads the repository at build time.
- **Live reload** — the source is bind-mounted over the image's `/app`, so a host edit reloads in the container. `scripts/serve.py` serves `0.0.0.0:8000` with TLS from `certs/portfolio.pem`, which is why the healthcheck tries https before http.
- **`stop_signal: SIGINT`** — the container's PID 1 is `serve.py`, and the kernel drops a signal that would take its default action for PID 1. Python handles SIGINT (Ctrl-C) but not SIGTERM, so the stock signal left every stop waiting out the ten-second grace period and being killed. SIGINT is what makes `scripts/dev.sh stop` return at once, with a clean exit code.
- **`METRICS_ENDPOINT`** passes through from the host environment; empty disables the beacon. `GIT_WORK_TREE=/app` is set for the plugins that read the repository.
- **The ignore file is [`Dockerfile.dockerignore`](Dockerfile.dockerignore), not `.dockerignore`.** Ignores are read from the build *context* — here the repository root — and a plain `.dockerignore` in this folder would apply only to a build whose context was the folder itself. The `<Dockerfile>.dockerignore` form beside the Dockerfile wins over the context root's, which is how this folder keeps its own rules without duplicating them at the root.

`certs/` is local and gitignored — per-project mkcert certificates for `*.mathewmusango.test`. The compose service passes their paths, so the dev server needs them present.

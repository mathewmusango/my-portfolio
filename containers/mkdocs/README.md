# containers/mkdocs (the MkDocs dev image)

One image and one compose service: the site's live-reload dev server — [`Dockerfile`](Dockerfile) built by [`compose.yaml`](compose.yaml).

```sh
podman-compose -f containers/mkdocs/compose.yaml up -d
```

## What it is

- **The build context is the repository root, not this folder.** The image `COPY`s `requirements.txt`, `mkdocs.yml`, `docs/` and `overrides/` from the context, which is why `compose.yaml` declares `context: ../..` and every bind mount is written `../../`.
- **Python 3.12 slim plus git**, because the revision-date plugin reads the repository at build time.
- **Live reload** — the source is bind-mounted over the image's `/app`, so a host edit reloads in the container. `scripts/serve.py` serves `0.0.0.0:8000` with TLS from `certs/portfolio.pem`, which is why the healthcheck tries https before http.
- **`METRICS_ENDPOINT`** passes through from the host environment; empty disables the beacon. `GIT_WORK_TREE=/app` is set for the plugins that read the repository.
- **The ignore file is [`Dockerfile.dockerignore`](Dockerfile.dockerignore), not `.dockerignore`.** Ignores are read from the build *context* — here the repository root — and a plain `.dockerignore` in this folder would apply only to a build whose context was the folder itself. The `<Dockerfile>.dockerignore` form beside the Dockerfile wins over the context root's, which is how this folder keeps its own rules without duplicating them at the root.

`certs/` is local and gitignored — per-project mkcert certificates for `*.mathewmusango.test`. The compose service passes their paths, so the dev server needs them present.

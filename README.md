# Mathew Musango Peter

Personal cloud-resume site for **Mathew Musango Peter** — Platform Engineering & Infrastructure Leader.
Built with **MkDocs + Material for MkDocs**, dark-teal theme, containerized with podman.

Live: <https://mathewmusango.github.io/my-portfolio/>

## Tech Stack

| Layer      | Tooling                                                               |
| ---------- | --------------------------------------------------------------------- |
| Site       | [MkDocs](https://www.mkdocs.org/) 1.6.1 + [Material](https://squidfunk.github.io/mkdocs-material/) 9.7.7 |
| Theme      | Material — dark slate (default), light toggle, teal `#00897b` accent   |
| Container  | Podman + `podman-compose` (Dockerfile + compose.yaml)                  |
| PDF viewer | pdf.js (self-hosted) with clickable, new-tab links overlays            |

## Getting Started

Start the dev server (http://localhost:8000, live reload):

```sh
podman-compose -f compose.yaml up -d
```

After editing any content, restart the container to pick changes up:

```sh
podman restart my-portfolio
```

## Deployment & CI

- **CI** (`.github/workflows/ci.yml`) — on every push/PR to `main`: installs deps, runs
  `mkdocs build --strict`, and sanity-checks the CSS.
- **Deploy** (`.github/workflows/deploy.yml`) — on push to `main` (or manual dispatch): builds the
  site and force-pushes the static output to the `gh-pages` branch of this repository, which GitHub
  Pages serves at <https://mathewmusango.github.io/my-portfolio/>. No external secrets are required.

## License

[MIT](LICENSE)

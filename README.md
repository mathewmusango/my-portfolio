# Mathew Musango Peter

Personal cloud-resume site for **Mathew Musango Peter** — Platform Engineering & Infrastructure Leader.
Built with **MkDocs + Material for MkDocs**, dark-teal theme.

Live: <https://mathewmusango.github.io/my-portfolio/>

## Tech Stack

| Layer      | Tooling                                                               |
| ---------- | --------------------------------------------------------------------- |
| Site       | [MkDocs](https://www.mkdocs.org/) 1.6.1 + [Material](https://squidfunk.github.io/mkdocs-material/) 9.7.7 |
| Theme      | Material — dark slate (default), light toggle, teal `#00897b` accent   |
| PDF viewer | pdf.js (self-hosted) with clickable, new-tab links overlays            |

## Development

This repo is the **production mirror** — it exists so GitHub Actions can build and deploy the
site. Local development (live-reload dev server with podman, `compose.yaml`) happens in the
private source repo.

## Deployment & CI

- **CI** (`.github/workflows/ci.yml`) — on every push/PR to `main`: installs deps, runs
  `mkdocs build --strict`, and sanity-checks the CSS.
- **Deploy** (`.github/workflows/deploy.yml`) — on push to `main` (or manual dispatch): builds the
  site and force-pushes the static output to the `gh-pages` branch of this repository, which GitHub
  Pages serves at <https://mathewmusango.github.io/my-portfolio/>. No external secrets are required.

## License

[MIT](LICENSE)

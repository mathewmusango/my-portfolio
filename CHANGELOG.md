# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-08-10

### Changed
- Release workflow now generates a CycloneDX SBOM (`sbom.cdx.json`) from `requirements.txt` and attaches it to every GitHub Release alongside `site.zip`.

## [1.1.0] - 2026-08-10

### Added
- Header GitHub repository button (repo icon links to the site repository).
- Page created/updated dates via `mkdocs-git-revision-date-localized` and contributor info via `mkdocs-git-committers-plugin-2`.
- Footer GitHub profile link.

### Changed
- Replaced the blue release-notes footer bar with a plain footer (git dates + GitHub profile link).
- Removed the "Edit this page"/"View source" actions (`edit_uri`, `content.action.edit/view`).
- Pinned all Python dependencies in `requirements.txt` for reproducible builds (`mkdocs-git-revision-date-localized-plugin==1.5.3`, `mkdocs-git-committers-plugin-2==2.5.0`).
- Release workflow now generates release notes from the CHANGELOG section for the tagged version.

 - 2026-08-09

### Added
- Initial site: personal cloud-resume for Mathew Musango Peter — MkDocs + Material, dark slate theme with teal accents.
- Pages: Home, About, Professional Experience, Technical Expertise, Projects, Certifications, Resume, Contact.
- Containerized workflow with podman (`compose.yaml`): live-reload dev server on port 8000 with a `/health` endpoint.
- Certifications: provider accordions, badge cards, and an in-page credential popup (badge links to the credential).
- Portfolio link in the resume PDF header (Email | LinkedIn | Portfolio | Nairobi, Kenya).
- CI/CD: GitHub Actions CI + deploy workflow publishing the built site to GitHub Pages (`gh-pages` branch), and a release workflow creating a GitHub Release from `v*` tags.

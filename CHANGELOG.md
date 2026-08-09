# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-09

### Added
- Initial site: personal cloud-resume for Mathew Musango Peter — MkDocs + Material, dark slate theme with teal accents.
- Pages: Home, About, Professional Experience, Technical Expertise, Projects, Certifications, Resume, Contact.
- Containerized workflow with podman (`compose.yaml`): live-reload dev server on port 8000 with a `/health` endpoint.
- Certifications: provider accordions, badge cards, and an in-page credential popup (badge links to the credential).
- Portfolio link in the resume PDF header (Email | LinkedIn | Portfolio | Nairobi, Kenya).
- CI/CD: GitHub Actions CI + deploy workflow publishing the built site to GitHub Pages (`gh-pages` branch), and a release workflow creating a GitHub Release from `v*` tags.

## [Unreleased]

### Changed
- Release workflow now generates release notes from the CHANGELOG section for the tagged version.

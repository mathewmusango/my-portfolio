# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-08-21

### Added
- **i18n folder structure**: pages now live in `docs/en/`, `docs/es/`, `docs/zh/` (was flat `*.es.md`/`*.zh.md` suffix naming) — rendered URLs unchanged.
- **Localized error pages**: `500` page translated per language (`/500/`, `/es/500/`, `/zh/500/`), and the `404` page is JS-localized from the URL prefix (`/es/`, `/zh/`) since it's a single static template.
- **Real issuer logos** for the two Coursera certifications: official Google wordmark and the official CU Boulder interlocking mark (replacing placeholder icons).
- **JS/CSS minification** (`mkdocs-minify-plugin`) alongside HTML — custom scripts listed in `js_files`/`css_files` (already-minified pdf.js excluded).
- **Translation staleness check** in CI: an English page committed after its `es`/`zh` translation fails the build until the translation is updated (git commit timestamps).
- **`site_url` canonical config**: sitemap, canonical links, and hreflang alternates now correct in every build (previously only prod CI injected it; local/test builds emitted a broken `None` sitemap).
- **In-depth documentation**: `MKDOCS.md` (mkdocs.yml reference) and refreshed `README.md`; `DEVOPS.md` updated.

### Changed
- `check_translations.py` now enforces presence **and** staleness (heading drift remains a warning).
- The shared build action only injects `site_url` when the config key is absent.

### Fixed
- `404` page broken rendering (a stray `</script>` corrupted the localization script — replaced the fragile regex with string matching).
- `docs/assets/pdf-viewer.html` now references the minified viewer script.

## [2.1.0] - 2026-08-13

### Added
- **Chinese (简体中文) localization**: the full site is available in Chinese, with the header language switcher now offering English, Español, and 中文.
- **Chinese resume PDF** (`resume-zh.pdf`), wired into the Chinese resume page (viewer, download, new-tab).

## [2.0.0] - 2026-08-13

### Added
- **Full Spanish localization**: the entire site is available in Spanish with a header language switcher (globe icon), per-language navigation, and translated pages (Home, About, Experience, Skills, Projects, Certifications, Resume, Contact).
- **Multilingual resume**: a Spanish resume PDF alongside the English one, with the resume viewer, download, and new-tab actions wired per language.

### Changed
- Content refresh across Home, About, Experience, Skills, Projects, Certifications, and Contact (updated taglines, narratives, and copy; "Eclectics International" naming; refreshed language levels).
- Typography: Space Grotesk headings + Inter body.
- Contact page redesigned with side-by-side cards.
- Resume PDF restyled: neutral headings, standard blue hyperlinks.
- Home hero shows an "Email" label instead of the raw address.

### Fixed
- Spanish asset paths (logos, resume PDF, credential badges) under `/es/`.
- Resume PDF worker path on the Spanish page and the standalone viewer.
- Language-switcher navigation (removed `navigation.instant` for correct per-page switching).

## [1.4.0] - 2026-08-13

### Added
- New "Away from the Keyboard" section on the About page.
- Contact page redesigned with side-by-side Email / LinkedIn cards and refreshed copy.

### Changed
- Typography: Space Grotesk headings + Inter body (replacing Saira Extra Condensed + Muli).
- Home page: refreshed About Me intro, Featured Project, and Connect sections (project stack chips kept).
- About page: updated tagline, subtitle, "In a Nutshell" items, and language levels; streamlined "My Story".
- Experience page: refreshed role descriptions and contributions.
- Certifications: clearer stats line (25 · 23 Credly-verified · AWS ×2 · The Linux Foundation ×21).
- Resume PDF: neutral heading colors, standard blue hyperlinks (no underline), refreshed narrative from the source resume, "Eclectics International" naming, and updated language levels.

## [1.3.0] - 2026-08-10

### Added
- Search: suggest + highlight features and a custom tokenizer separator for technical terms.
- Minified HTML output (`mkdocs-minify-plugin`).
- Copyright footer line.
- Abbreviation tooltips (`abbr` + `content.tooltips`), footnotes, and auto-linking of bare URLs (`pymdownx.magiclink`).

### Changed
- CI/CD: actions bumped to Node 24 majors; site artifact retention set to 7 days; deploy commits authored as `mathewmusango`.
- Repo hygiene: `SECURITY.md`, `.gitattributes`, Dependabot (pip + Actions), issue templates; new `DEVOPS.md` in the source repo.

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

## [1.0.0] - 2026-08-09

### Added
- Initial site: personal cloud-resume for Mathew Musango Peter — MkDocs + Material, dark slate theme with teal accents.
- Pages: Home, About, Professional Experience, Technical Expertise, Projects, Certifications, Resume, Contact.
- Containerized workflow with podman (`compose.yaml`): live-reload dev server on port 8000 with a `/health` endpoint.
- Certifications: provider accordions, badge cards, and an in-page credential popup (badge links to the credential).
- Portfolio link (`mathewmusango.github.io/my-portfolio`) added to the resume PDF header (Email | LinkedIn | Portfolio | Nairobi, Kenya).
- CI/CD: GitHub Actions CI (`ci.yml` — strict build validation) on this repo. The public
  `mathewmusango/my-portfolio` repo (production) carries its own CI + deploy workflow, publishing
  the built site to its `gh-pages` branch via GitHub Pages.
- GitHub Actions release workflow (`release.yml`): pushing a `v*` tag builds the site and creates a
  GitHub Release with the site archive attached.

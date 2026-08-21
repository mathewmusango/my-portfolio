# Security Policy

## Reporting a Vulnerability

This is a personal portfolio/resume site — static content with no authentication or
user data. If you find a security issue in the site, its build pipeline, or its
dependencies, please report it **privately** instead of opening a public issue:

- **Email:** [Email me](mailto:musangomathew@gmail.com)

Include a description of the issue, steps to reproduce, and the affected component
(site content, dependencies, CI/CD). Reports are acknowledged within 7 days.

## Supported Versions

Security fixes are applied to the latest release. Dependencies are pinned in
`requirements.txt`, audited on every CI build (`pip-audit`), and every release ships
a CycloneDX SBOM (`sbom.cdx.json`) for downstream review.

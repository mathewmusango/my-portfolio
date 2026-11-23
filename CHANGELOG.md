# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), a tag (`v<YYYY>.<MMDD>.<HHMM>Z`)
marks a release, and its section is written from the issues that release closed — one line
per issue, the label deciding the section.

Hand-written history from before 2026-11-23 is in
[CHANGELOG-archive.md](CHANGELOG-archive.md).

## [Unreleased]

### Changed

- terraform: split into site & metrics stacks with per-service modules ([#192](https://github.com/mathewmusango/my-portfolio/issues/192))
- ci(terraform): two matrixed jobs (site, metrics) across staging/prod, automatic apply ([#194](https://github.com/mathewmusango/my-portfolio/issues/194))
- ci(terraform): let the Infra dispatch target a single stack (site | metrics | both) ([#204](https://github.com/mathewmusango/my-portfolio/issues/204))
- fix(terraform): declare TLSv1 for the default-cert CloudFront distributions ([#206](https://github.com/mathewmusango/my-portfolio/issues/206))
- terraform: keep the root split from replacing IAM policies and rewriting the OAC description ([#208](https://github.com/mathewmusango/my-portfolio/issues/208))
- terraform: delete the temporary moved blocks in modules/lambda ([#210](https://github.com/mathewmusango/my-portfolio/issues/210))
- docs(changelog): document the root-split description fix for the release ([#213](https://github.com/mathewmusango/my-portfolio/issues/213))
- docs: reflect the landed terraform split and auto-apply ([#217](https://github.com/mathewmusango/my-portfolio/issues/217))
- ci: one gated job per environment in the deploy workflows ([#219](https://github.com/mathewmusango/my-portfolio/issues/219))
- ci: keep the deploy plane jobs separate and borrow only the matrix shape ([#221](https://github.com/mathewmusango/my-portfolio/issues/221))
- ci(terraform): cache Terraform providers across Deploy: Infra runs ([#223](https://github.com/mathewmusango/my-portfolio/issues/223))
- ci: seed the terraform check caches from main, and advance the library pin ([#225](https://github.com/mathewmusango/my-portfolio/issues/225))
- Re-vendor the pinned JS when package.json changes ([#246](https://github.com/mathewmusango/my-portfolio/issues/246))
- Re-vendor at build time so a package.json bump builds and deploys ([#251](https://github.com/mathewmusango/my-portfolio/issues/251))
- Cache the dev image's dependency layers and stop baking node_modules ([#253](https://github.com/mathewmusango/my-portfolio/issues/253))
- Group scripts by kind and trim the dev image's Dockerfile ([#255](https://github.com/mathewmusango/my-portfolio/issues/255))
- Audit the npm dependencies and name every workflow for its group ([#257](https://github.com/mathewmusango/my-portfolio/issues/257))
- Require the two dependency-audit contexts on main ([#259](https://github.com/mathewmusango/my-portfolio/issues/259))
- Run the dependency audits in the local check driver ([#261](https://github.com/mathewmusango/my-portfolio/issues/261))
- Keep gitleaks as a local pre-commit net ([#263](https://github.com/mathewmusango/my-portfolio/issues/263))
- ci: re-pin the security leaves to the gitleaks-free tag ([#267](https://github.com/mathewmusango/my-portfolio/issues/267))
- ci: drop the rationale comment from the local check driver ([#270](https://github.com/mathewmusango/my-portfolio/issues/270))
- The library pins predate the current release tag ([#290](https://github.com/mathewmusango/my-portfolio/issues/290))
- Flatten containers/ to the repository root and drop the pre-commit hook ([#302](https://github.com/mathewmusango/my-portfolio/issues/302))


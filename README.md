# My Portfolio

[![build](https://img.shields.io/github/actions/workflow/status/mathewmusango/my-portfolio/build.yml?branch=main&label=build)](https://github.com/mathewmusango/my-portfolio/actions/workflows/build.yml)
[![checks](https://img.shields.io/github/actions/workflow/status/mathewmusango/my-portfolio/checks.yml?branch=main&label=checks)](https://github.com/mathewmusango/my-portfolio/actions/workflows/checks.yml)
[![security](https://img.shields.io/github/actions/workflow/status/mathewmusango/my-portfolio/security.yml?branch=main&label=security)](https://github.com/mathewmusango/my-portfolio/actions/workflows/security.yml)
[![codeql](https://img.shields.io/github/actions/workflow/status/mathewmusango/my-portfolio/codeql.yml?branch=main&label=codeql)](https://github.com/mathewmusango/my-portfolio/actions/workflows/codeql.yml)
[![web](https://img.shields.io/badge/web-view-green.svg)](https://mathewmusango.github.io/my-portfolio/)
[![tag](https://img.shields.io/github/v/tag/mathewmusango/my-portfolio?label=tag)](https://github.com/mathewmusango/my-portfolio/tags)
[![license](https://img.shields.io/github/license/mathewmusango/my-portfolio?label=license)](https://github.com/mathewmusango/my-portfolio/blob/main/LICENSE)

<p align="center">
  <img alt="MkDocs 1.6.1" src="https://img.shields.io/badge/MkDocs-1.6.1-526CFE?logo=readthedocs&logoColor=white">
  <img alt="Material 9.7.7" src="https://img.shields.io/badge/Material-9.7.7-00897b?logo=materialformkdocs&logoColor=white">
  <img alt="pdf.js 6.4.299" src="https://img.shields.io/badge/pdf.js-6.4.299-b30b00">
  <img alt="Mermaid" src="https://img.shields.io/badge/Mermaid-ff3670?logo=mermaid&logoColor=white">
  <img alt="Terraform" src="https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white">
  <img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-2088FF?logo=githubactions&logoColor=white">
  <img alt="AWS: S3, CloudFront, API Gateway, Lambda, DynamoDB" src="https://img.shields.io/badge/AWS-S3_%C2%B7_CloudFront_%C2%B7_API_Gateway_%C2%B7_Lambda_%C2%B7_DynamoDB-FF9900?logo=amazonwebservices&logoColor=white">
</p>

![Site preview](docs/assets/site-preview.png)
*The live site — [mathewmusango.github.io/my-portfolio](https://mathewmusango.github.io/my-portfolio/)*

> **Personal project developed in the open** — the process here is deliberate practice,
> not a community project.
>
> My open-source work lives in **[Emuplane](https://github.com/mathewmusango/emuplane)**,
> my first OSS project: a console and control plane for AWS-compatible emulators, where
> open source and software delivery (DevOps, DevSecOps, platform engineering, security,
> operations) have room to go further, along with best coding practice.

This repository is the source of
[mathewmusango.github.io/my-portfolio](https://mathewmusango.github.io/my-portfolio/):
a platform engineer's portfolio built with MkDocs + Material and run like a production
service — gated multi-environment releases, least-privilege OIDC roles, and visitor
analytics that never store an IP address.

| What | Terms |
| --- | --- |
| **Code** | MIT — see [LICENSE](LICENSE) |
| **Content** | © Mathew Musango Peter, all rights reserved — text, resume, certifications and images |

## What is in here

| Part | What it is |
| --- | --- |
| **Content delivery** | One `docs/` tree in three languages (en · es · zh), built once and promoted to staging, to the prod S3 + CloudFront mirror (OAC only) and to GitHub Pages |
| **Visitor analytics** | CloudFront geo headers → API Gateway → writer / reader Lambdas → DynamoDB — no IPs stored, 90-day TTL |
| **Infrastructure** | Terraform: `bootstrap` (state backends + per-job OIDC roles) plus the `infra/site` and `infra/metrics` roots, one state each |

**[Platform Architecture](https://mathewmusango.github.io/my-portfolio/atlas/platform-architecture/)**
on the site shows how the three parts fit together, diagrams included; the AWS
implementation is in [`terraform/README.md`](terraform/README.md).

## Documentation

- [The live site](https://mathewmusango.github.io/my-portfolio/) — profile, experience,
  projects, skills, resume.
- [`terraform/README.md`](terraform/README.md) — the site and metrics stacks, the event
  schema, security and local AWS emulation.
- [`scripts/README.md`](scripts/README.md) — the dev image, the tooling and the check
  scripts CI runs.
- [`SECURITY.md`](SECURITY.md) — vulnerability reporting.
- [`CHANGELOG.md`](CHANGELOG.md) — release history.

## License

[MIT](LICENSE)

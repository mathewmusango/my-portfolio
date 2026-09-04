---
icon: material/layers-triple
hide:
  - toc
---

# Platform Architecture {#platform-architecture}

The [repository](https://github.com/mathewmusango/my-portfolio){ target="_blank" rel="noopener" }
behind this site is a three-part platform — **content delivery**, **visitor
metrics**, and the **Terraform control plane** behind both. These are the same
diagrams the repo
[README](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
carries; this page gives them a home on the site. The
[Site Structure](structure.md) map shows where pages live; this page shows how
the platform works.

## Site — content delivery

```mermaid
flowchart LR
    subgraph Local[dev]
        DEV[podman-compose · serve.py<br/>HTTPS via mkcert]
    end
    subgraph GHA[GitHub Actions]
        B[ci.yml — build + checks] -->|main| D1[deploy-staging-s3]
        B -->|v* tag| D2[deploy-pre-prod-s3]
        B -->|v* tag| D3[deploy-prod-pages]
    end
    D1 --> STG[staging — S3 + CloudFront · OAC]
    D2 --> PRE[pre-prod — S3 + CloudFront · OAC]
    D3 --> PRD[prod — GitHub Pages]
```

**Prod is gated**: the Pages deploy runs behind a required reviewer in the `prod`
GitHub environment — the AWS mirror (`pre-prod`) lands first, then Pages ships on
approval. Two delivery planes, each with its own gate: **content** — `main` →
staging · `v*` → pre-prod → gated Pages; **infrastructure** — `main` → staging
auto-applies · `v*` → prod plan-only.

## Metrics — visitor analytics

```mermaid
flowchart LR
    V[site visitor] -->|POST /event| CF[CloudFront<br/>geo headers]
    CF --> GW[API Gateway]
    GW -->|POST /event| W[Lambda — writer]
    GW -->|GET /summary · /views · /health| R[Lambda — reader]
    W -->|PutItem| DB[(DynamoDB<br/>TTL 90 days)]
    R -->|Scan · Query| DB
```

CloudFront supplies the geo headers, so **no IP address ever reaches the Lambda**
([why?](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md#why-cloudfront){ target="_blank" rel="noopener" }).
Writer and reader lambdas each have their own least-privilege role; the API is
public but origin-gated. **staging** runs its own stack; **pre-prod + prod**
share one; **dev** runs Ministack (no edge). Raw events expire after 90 days.

## Terraform — the control plane

```mermaid
flowchart TB
    BOOT[terraform/ci — bootstrap<br/>manual · run as an AWS user] --> STATE[(state backends<br/>S3 + DynamoDB lock<br/>staging · prod · local dev)]
    BOOT --> ROLES[OIDC roles — least privilege, one per job<br/>-terraform · -deploy · -invalidate · -toggle]
    WORK[GitHub Actions workflows] -->|assume role| ROLES
    ROLES -->|plan · apply · sync| STACKS[site + metrics stacks<br/>staging · prod]
```

`terraform/ci` creates the per-environment state backends and the OIDC roles
GitHub Actions assumes to build and run the stacks. **Bootstrap is the one
out-of-band step** — an AWS user, outside GitHub Actions, creates them; no
workflow ever uses keys.

## How a change ships

```mermaid
flowchart LR
    M[push / PR to main] --> C{required checks<br/>per-surface · skip-model}
    V[v* tag<br/>ruleset-gated] --> C
    C -->|pass| B[Build — ci.yml]
    V --> B
    B --> A[site artifact]
    A -->|workflow_run · main| S[deploy → staging env]
    A -->|workflow_run · v*| P[deploy → pre-prod → gated prod]
    V --> R[release — tag + SBOM]
    T[tf change] --> TP[terraform plan] -->|manual apply| AP[apply]
    X[workflow_dispatch] --> TG[toggle-env] & INV[invalidate]
```

Implementation reference (every workflow, role, and operational extra):
[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }.

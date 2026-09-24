---
icon: material/layers-triple
hide:
  - toc
---

# Arquitectura de la Plataforma {#platform-architecture}

El [repositorio](https://github.com/mathewmusango/my-portfolio){ target="_blank" rel="noopener" }
detrás de este sitio es una plataforma de tres partes — **entrega de contenido**,
**métricas de visitantes** y el **plano de control de Terraform** detrás de
ambas. Son los mismos diagramas que lleva el
[README](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
del repositorio; esta página les da un hogar en el sitio. El mapa de
[Estructura del Sitio](structure.md) muestra dónde viven las páginas; esta
página muestra cómo funciona la plataforma.

## Sitio — entrega de contenido

```mermaid
flowchart LR
    subgraph Local[dev]
        DEV[podman-compose · serve.py<br/>HTTPS via mkcert]
    end
    subgraph GHA[GitHub Actions]
        B[ci.yml — build + checks] -->|main| DS[deploy.yml · staging]
        B -->|v* tag| DP[deploy.yml · prod · required reviewer]
    end
    DS --> STG[staging — S3 + CloudFront · OAC]
    DP --> PAWS[prod — S3 + CloudFront · OAC]
    DP --> PPAGES[prod — GitHub Pages]
```

**Prod está protegido por una puerta**: `v*` entrega un solo artefacto a ambos
planos de prod — el espejo AWS (S3 + CloudFront) y GitHub Pages (el sitio
canónico) — y ambos esperan al revisor obligatorio en el entorno `prod` de
GitHub, así que nada llega a prod sin revisión. Dos planos de entrega, cada uno
con su propia puerta: **contenido** — `main` → staging · `v*` → prod
(revisado); **infraestructura** — `main` → staging se aplica solo · `v*` →
solo plan en prod.

## Métricas — analítica de visitas

```mermaid
flowchart LR
    V[site visitor] -->|POST /event| CF[CloudFront<br/>geo headers]
    CF --> GW[API Gateway]
    GW -->|POST /event| W[Lambda — writer]
    GW -->|GET /summary · /views · /health| R[Lambda — reader]
    W -->|PutItem| DB[(DynamoDB<br/>TTL 90 days)]
    R -->|Scan · Query| DB
```

CloudFront suministra las cabeceras geo, por lo que **ninguna dirección IP llega
jamás a la Lambda**
([¿por qué?](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md#why-cloudfront){ target="_blank" rel="noopener" }).
Las lambdas escritora y lectora tienen cada una su propio rol de mínimo
privilegio; la API es pública pero restringida por origen. **staging** ejecuta su
propia pila; **prod** usa una sola; **dev** ejecuta Ministack (sin
edge). Los eventos brutos expiran a los 90 días.

## Terraform — el plano de control

```mermaid
flowchart TB
    BOOT[terraform/bootstrap<br/>manual · run as an AWS user] --> STATE[(state backends<br/>S3 + DynamoDB lock<br/>staging · prod · local dev)]
    BOOT --> ROLES[OIDC roles — least privilege, one per job<br/>-terraform · -deploy · -invalidate · -toggle]
    WORK[GitHub Actions workflows] -->|assume role| ROLES
    ROLES -->|plan · apply · sync| STACKS[site + metrics stacks<br/>staging · prod]
```

`terraform/bootstrap` crea los backends de estado por entorno y los roles OIDC que
GitHub Actions asume para construir y ejecutar las pilas. **El bootstrap es el
único paso fuera de banda** — un usuario de AWS, fuera de GitHub Actions, los
crea; ningún workflow usa jamás claves.

## Cómo se publica un cambio

```mermaid
flowchart LR
    M[push / PR to main] --> C{required checks<br/>per-surface · skip-model}
    V[v* tag<br/>ruleset-gated] --> C
    C -->|pass| B[ci — ci.yml]
    V --> B
    B --> A[site artifact]
    A -->|workflow_run · main| S[deploy → staging]
    A -->|workflow_run · v*| P[deploy → prod · reviewed]
    V --> R[release — tag + SBOM]
    T[tf change] --> TP[terraform plan] -->|manual apply| AP[apply]
    X[workflow_dispatch] --> CF[cloudfront.yml · invalidate/switch]
```

Referencia de implementación (cada workflow, rol y extra operativo):
[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }.

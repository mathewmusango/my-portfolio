---
icon: material/layers-triple
tags:
  - Platform Engineering
  - CI/CD
  - Terraform
  - AWS
  - GitHub Actions
  - MkDocs
  - DevSecOps
  - IaC
---

# La Plataforma Detrás de Este Sitio

> Los diagramas de arquitectura de esta plataforma viven en el mapa de
> [Estructura del Sitio](../../atlas/structure/) y en los
> [diagramas del README](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
> del repositorio — esta página es la historia, no el volcado de diagramas.

Este portafolio es el producto — y este repositorio es la plataforma de
ingeniería que lo construye, lo verifica, lo despliega y lo opera. El sitio que
estás leyendo se ejecuta sobre el mismo repo que documenta: un producto MkDocs +
Material con un sistema de entrega de grado de producción a su alrededor,
desarrollado en abierto como una demostración deliberada de cómo se hace
ingeniería de plataformas en un sistema pequeño, real y público.

- **El producto (el sitio):** [mathewmusango.github.io/my-portfolio](https://mathewmusango.github.io/my-portfolio/){ target="_blank" rel="noopener" }
- **La plataforma (este repo):** [mathewmusango/my-portfolio](https://github.com/mathewmusango/my-portfolio){ target="_blank" rel="noopener" }
- **El código:** [licencia MIT](https://github.com/mathewmusango/my-portfolio/blob/main/LICENSE){ target="_blank" rel="noopener" } — el contenido personal © el autor.

## ¿Por qué una plataforma para un portafolio?

Un sitio de portafolio es pequeño; el proceso que lo rodea no tiene por qué
serlo. Este proyecto aplica deliberadamente las prácticas que se esperan del
software de producción — en un repositorio público, a escala de portafolio,
donde cada decisión es visible:

- **Todo se publica como software real** — PRs, verificaciones obligatorias, aprobaciones, releases.
- **Cada entorno es un entorno real** — dev, staging, pre-prod, prod.
- **La seguridad está diseñada desde el inicio** — sin credenciales de larga duración, almacenamiento privado, mínimo privilegio.
- **La privacidad es una propiedad arquitectónica** — la analítica de visitas recoge solo geo, nunca IPs.
- **La historia es honesta** — un [CHANGELOG](https://github.com/mathewmusango/my-portfolio/blob/main/CHANGELOG.md){ target="_blank" rel="noopener" }, releases etiquetados y un [SBOM por release](https://github.com/mathewmusango/my-portfolio/releases){ target="_blank" rel="noopener" }.

El valor no está en la escala — está en la disciplina. Esta página documenta la
plataforma: su arquitectura, su modelo de entrega, su gobernanza, su postura de
seguridad y los incidentes reales que la moldearon.

## Arquitectura

La plataforma tiene tres partes — **entrega de contenido**, **métricas de
visitantes** y el **plano de control de Terraform** detrás de ambas. (Vistas
interactivas: el [diagrama de estructura del sitio](../../atlas/structure/)
mapea el sitio; el [README](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
del repositorio lleva los diagramas de entrega, métricas y plano de control.)

### Sitio — entrega de contenido

Tres destinos de despliegue, un solo artefacto. `main` despliega a **staging**
(un par S3 + CloudFront en AWS, bucket privado, servido a través de OAC). Las
etiquetas `v*` despliegan a **pre-prod** — un espejo AWS del sitio canónico — y
luego a **prod**: GitHub Pages, detrás de un revisor obligatorio en el entorno
`prod`.

### Métricas — analítica de visitas

Una pila de métricas deliberadamente pequeña y completamente serverless.
CloudFront suministra las cabeceras geo — por lo que **ninguna dirección IP llega
jamás a la Lambda**. El escritor almacena país/ciudad/región con un TTL de 90
días; el lector sirve las páginas de [Métricas del sitio](../../metrics/). Cada
Lambda tiene su propio rol de mínimo privilegio; la API es pública pero
restringida por origen ([¿por qué CloudFront?](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md#why-cloudfront){ target="_blank" rel="noopener" }).

### Terraform — el plano de control

`terraform/ci` crea los backends de estado por entorno y los roles OIDC que
GitHub Actions asume para construir y ejecutar las pilas. **El bootstrap es el
único paso fuera de banda** — un usuario de AWS, fuera de GitHub Actions, los
crea con sus propios permisos IAM; ningún workflow usa jamás claves. Detalle de
implementación:
[`terraform/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md){ target="_blank" rel="noopener" }.

## Modelo de entrega

Dos planos de entrega, cada uno con su propia puerta:

| Plano | Ruta | Puerta |
|---|---|---|
| **Contenido** | `main` → staging · `v*` → pre-prod → Pages con puerta | revisor obligatorio en `prod` |
| **Infraestructura** | `main` → staging se aplica solo · `v*` → solo plan en prod | `terraform apply` manual |

Los despliegues se ejecutan en cada build de CI correcto de la ref adecuada
([#20](https://github.com/mathewmusango/my-portfolio/pull/20){ target="_blank" rel="noopener" }
dividió prod en Pages + S3 y pasó a las acciones oficiales de Pages). Staging se
**omite** cuando el artefacto construido es byte-idéntico al último despliegue —
un esquema de marcador por hash de contenido que evita que las fusiones solo de
documentación agiten el bucket
([#29](https://github.com/mathewmusango/my-portfolio/pull/29){ target="_blank" rel="noopener" },
[#31](https://github.com/mathewmusango/my-portfolio/pull/31){ target="_blank" rel="noopener" }).

## Flujo de desarrollo

- El repositorio es la **fuente única de verdad** — el mismo árbol `docs/` construye localmente y en CI.
- **Solo contenedores** — `podman-compose up` ejecuta el servidor de desarrollo de MkDocs; no se necesita Python/venv local.
- **HTTPS local** mediante una CA raíz [mkcert](https://github.com/FiloSottile/mkcert){ target="_blank" rel="noopener" } por máquina — paridad con el TLS del sitio desplegado.
- El contenedor de desarrollo también sirve un endpoint `/health` usado por su propio healthcheck.
- Las verificaciones locales reflejan CI exactamente (`check-compose.yaml` + `scripts/check_changed.sh`).

Pasos de inicio: [el README del repositorio](https://github.com/mathewmusango/my-portfolio#getting-started){ target="_blank" rel="noopener" }.

## CI / CD

Un cambio se publica en cuatro fases — cada una documentada en
[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }:

1. **Build** — `mkdocs build` estricto (enlaces rotos, traducciones desactualizadas
   y desequilibrio de CSS rompen el build), `pip-audit` y un artefacto del sitio
   construido en cada push/PR a `main` y en cada etiqueta `v*`.
2. **Verificaciones** — un workflow por superficie
   (`checks-{shell,python,js,terraform,yml}`). Cada uno se activa según las rutas
   modificadas ([skip-model, #17](https://github.com/mathewmusango/my-portfolio/pull/17){ target="_blank" rel="noopener" }):
   las superficies no tocadas **se omiten y reportan éxito**, así las diez
   verificaciones obligatorias nunca bloquean un PR no relacionado.
3. **Deploy** — `workflow_run` al éxito del Build: `main` → staging, `v*` →
   pre-prod + prod con puerta (ver [Modelo de entrega](#modelo-de-entrega)).
4. **Release e infra** — las etiquetas `v*` crean un GitHub Release con un SBOM
   CycloneDX; Terraform planifica en cada cambio de infra (el apply sigue siendo
   manual); `toggle-env` / `invalidate-cloudfront` son extras operativos manuales.

Los nombres de las verificaciones son los nombres de las puertas — CI reporta
nombres de jobs (`ci-build`, `checks-python-ruff`, …) para que la protección de
rama y los rulesets exijan exactamente lo que se ejecuta
([#12](https://github.com/mathewmusango/my-portfolio/pull/12){ target="_blank" rel="noopener" }).

## Gobernanza

Rulesets-como-código protegen las dos refs que importan
([`rulesets/`](https://github.com/mathewmusango/my-portfolio/tree/main/rulesets){ target="_blank" rel="noopener" }):

| Ref | Protección |
|---|---|
| `main` | Solo PR: 1 aprobación, squash/rebase, revisiones obsoletas descartadas, las 10 verificaciones obligatorias, sin force-push, **sin bypass — el propietario incluido** |
| etiquetas `v*` | Creadas solo por el mantenedor; `ci-build` en verde requerido; inmutables una vez creadas |

La aplicación es en el momento del push y está verificada — los registros de
rechazo viven junto a las configuraciones en `rulesets/main.md` y
`rulesets/tags.md`. Los PRs llevan etiquetas de un conjunto curado (`ci` ·
`infra` · `security` · `governance` · `dependencies`), y una segunda cuenta de
GitHub revisa como colaboradora normal — el propietario no fusiona nada sin
aprobar. Las plantillas de issues imponen una estructura de siete partes
([#15](https://github.com/mathewmusango/my-portfolio/pull/15){ target="_blank" rel="noopener" },
[#18](https://github.com/mathewmusango/my-portfolio/pull/18){ target="_blank" rel="noopener" }).

## Seguridad

- **Sin claves de larga duración** — los despliegues y Terraform asumen roles de
  AWS vía OIDC ([#22](https://github.com/mathewmusango/my-portfolio/pull/22){ target="_blank" rel="noopener" }
  extendió la confianza para jobs con entorno).
- **Mínimo privilegio por job** — roles separados `-terraform` · `-deploy` ·
  `-invalidate` · `-toggle`; el edge de métricas de prod **no** tiene rol de
  toggle por diseño.
- **Almacenamiento privado** — los buckets S3 nunca son públicos; CloudFront los sirve solo a través de OAC.
- **API restringida por origen** — el endpoint de métricas es público pero
  limitado al origen configurado del sitio; WAF/VPC son opcionales (postura de
  Free Tier primero).
- **Higiene de dependencias** — [Dependabot](https://github.com/mathewmusango/my-portfolio/security/dependabot){ target="_blank" rel="noopener" },
  `pip-audit` en cada build, un SBOM CycloneDX en cada release, Checkov en CI.
- Política de reporte: [SECURITY.md](https://github.com/mathewmusango/my-portfolio/blob/main/SECURITY.md){ target="_blank" rel="noopener" }.

## Incidentes reales y las lecciones que dejaron

La plataforma se ha roto en producción de formas instructivas. Cada incidente
está documentado en el
[CHANGELOG](https://github.com/mathewmusango/my-portfolio/blob/main/CHANGELOG.md){ target="_blank" rel="noopener" };

| Incidente | Causa raíz | Solución |
|---|---|---|
| **Staging con 403 en cada objeto** | SSE-KMS es incompatible con CloudFront OAC (sin `kms:Decrypt`) | Revertido a AES256 ([`aee25c6`](https://github.com/mathewmusango/my-portfolio/commit/aee25c6){ target="_blank" rel="noopener" }) |
| **Staging quedó obsoleto en lotes multi-commit** | La puerta de despliegue comparaba solo `HEAD~1..HEAD` | Los despliegues ahora se ejecutan en cada build de CI correcto ([`1bf9bd9`](https://github.com/mathewmusango/my-portfolio/commit/1bf9bd9){ target="_blank" rel="noopener" }) |
| **Fusiones solo de docs agitaban el bucket** | `s3 sync` siempre resubía las extracciones nuevas | Omitir por marcador de hash de contenido ([#29](https://github.com/mathewmusango/my-portfolio/pull/29){ target="_blank" rel="noopener" }, [#31](https://github.com/mathewmusango/my-portfolio/pull/31){ target="_blank" rel="noopener" }) |
| **Verificaciones "Expected — waiting"** | Nombres obligatorios que ningún run había reportado aún | Registrar nombres primero; skip-model para activar por rutas ([#12](https://github.com/mathewmusango/my-portfolio/pull/12){ target="_blank" rel="noopener" }, [#17](https://github.com/mathewmusango/my-portfolio/pull/17){ target="_blank" rel="noopener" }) |

El patrón en cada uno: una falla real, una corrección de raíz y la actualización
del runbook que evita que se repita — el mismo ciclo que este sitio documenta
como [cronología de versiones](../../atlas/releases/).

## Cómo explorar

- **[README del repositorio](https://github.com/mathewmusango/my-portfolio/blob/main/README.md){ target="_blank" rel="noopener" }** — la vista del sistema: arquitectura, ejecución local.
- **[`terraform/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md){ target="_blank" rel="noopener" }** — implementación y justificación de la infraestructura.
- **[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }** — cada workflow, rol y extra operativo.
- **[`CONTRIBUTING.md`](https://github.com/mathewmusango/my-portfolio/blob/main/CONTRIBUTING.md){ target="_blank" rel="noopener" }** — cómo un cambio se convierte en una fusión.
- **[Atlas del sitio](../../atlas/)** — cronología de versiones, etiquetas y el mapa de estructura del sitio.
- **[GitHub Actions](https://github.com/mathewmusango/my-portfolio/actions){ target="_blank" rel="noopener" }** — el pipeline en vivo.

---
icon: material/chart-line
hide:
  - toc
---

# Métricas del sitio

Este sitio se construye y opera como una plataforma de producción — contenido con control de versiones, compilaciones automatizadas y verificaciones estrictas antes de publicar nada. Esta página es su panel de instrumentos: qué contiene, cómo se entrega y qué se mide. La única instrumentación en tiempo de ejecución es un beacon de primera parte y centrado en la privacidad que envía solo la ruta de la página y el idioma — cada cifra aquí es un hecho, no una suposición.

<div class="metrics-grid" markdown>

<div class="metrics-stat" markdown>

### :material-file-document: Páginas

**{{pages_total}}**

por idioma, totalmente trilingüe

</div>

<div class="metrics-stat" markdown>

### :material-translate: Idiomas

**3**

Inglés · Español · 中文

</div>

<div class="metrics-stat" markdown>

### :material-update: Última actualización

**{{last_updated}}**

el contenido se publica con cada release

</div>

<div class="metrics-stat" markdown>

### :material-rocket-launch: Entrega

**Automatizada**

GitHub Actions · build estricto · SBOM · Terraform IaC

</div>

</div>

## Datos en vivo

La analítica de visitas — vistas de página, idiomas y páginas principales, recopilada con privacidad — vive en su propia página.

[Ver análisis de visitas :material-account-eye:](analytics/){ .md-button .md-button--primary }

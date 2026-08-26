---
icon: material/chart-line
hide:
  - toc
---

# 站点指标

本网站的构建和运维方式与生产级平台一致——内容版本化、构建自动化，发布前经过严格检查。这个页面就是它的仪表盘：包含什么、如何交付、测量什么。唯一的运行时埋点是一个第一方、注重隐私的 beacon，只发送页面路径和语言——这里的每个数字都是事实，而非猜测。

<div class="metrics-grid" markdown>

<div class="metrics-stat" markdown>

### :material-file-document: 页面

**{{pages_total}}**

每种语言，完全三语

</div>

<div class="metrics-stat" markdown>

### :material-translate: 语言

**3**

English · Español · 中文

</div>

<div class="metrics-stat" markdown>

### :material-update: 最近更新

**{{last_updated}}**

内容随每次发布更新

</div>

<div class="metrics-stat" markdown>

### :material-rocket-launch: 交付

**自动化**

GitHub Actions · 严格构建 · SBOM · Terraform IaC

</div>

</div>

## 实时数据

访客分析——页面浏览量、语言和热门页面，以隐私为先收集——在其专属页面实时展示。

[查看访客分析 :material-account-eye:](analytics/){ .md-button .md-button--primary }

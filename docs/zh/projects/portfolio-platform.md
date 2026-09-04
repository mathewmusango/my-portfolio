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

# 本站背后的平台

> 本平台的架构图位于[站点结构](../../atlas/structure/)地图和仓库
> [README 图表](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
> 中 — 本页讲述故事，而非堆砌图表。

这个作品集就是产品 — 而这个仓库是构建、检查、部署和运维它的工程平台。你正在
阅读的站点运行在它所记录的同一个仓库上：一个 MkDocs + Material 产品，周围环绕
着一套达到生产标准的交付体系，并以开源方式公开开发，作为对"如何在一个小型、
真实、公开的系统上做平台工程"的刻意示范。

- **产品（站点）：** [mathewmusango.github.io/my-portfolio](https://mathewmusango.github.io/my-portfolio/){ target="_blank" rel="noopener" }
- **平台（本仓库）：** [mathewmusango/my-portfolio](https://github.com/mathewmusango/my-portfolio){ target="_blank" rel="noopener" }
- **代码：** [MIT 许可](https://github.com/mathewmusango/my-portfolio/blob/main/LICENSE){ target="_blank" rel="noopener" } — 个人内容 © 作者。

## 为什么给作品集造一个平台？

作品集站点很小；但围绕它的流程不必小。这个项目刻意把生产软件应有的实践用在一个
公开仓库、作品集规模之上 — 在这里每一项权衡都清晰可见：

- **一切按真实软件发布** — PR、必需检查、审批、发布。
- **每个环境都是真实环境** — dev、staging、pre-prod、prod。
- **安全是设计出来的** — 没有长期凭证、私有存储、最小权限。
- **隐私是架构属性** — 访客分析只采集地理信息，绝不采集 IP。
- **历史是诚实的** — [CHANGELOG](https://github.com/mathewmusango/my-portfolio/blob/main/CHANGELOG.md){ target="_blank" rel="noopener" }、带标签的发布，以及[每次发布的 SBOM](https://github.com/mathewmusango/my-portfolio/releases){ target="_blank" rel="noopener" }。

价值不在于规模 — 而在于纪律。本页记录平台本身：它的架构、交付模型、治理、
安全态势，以及塑造它的真实事故。

## 架构

平台由三部分组成 — **内容交付**、**访客指标**，以及支撑两者的 **Terraform
控制平面**。（交互视图：[站点结构图](../../atlas/structure/) 描绘站点；仓库
[README](https://github.com/mathewmusango/my-portfolio#architecture){ target="_blank" rel="noopener" }
承载交付、指标和控制平面图表。）

### 站点 — 内容交付

三个部署目标，一个构建产物。`main` 部署到 **staging**（AWS 中的 S3 + CloudFront
组合，bucket 私有，通过 OAC 服务）。`v*` 标签部署到 **pre-prod** — 规范站点的
AWS 镜像 — 然后到 **prod**：GitHub Pages，位于 `prod` 环境的必需审阅者之后。

### 指标 — 访客分析

一个刻意做小、完全 serverless 的指标栈。CloudFront 提供地理信息头 — 因此
**任何 IP 地址都不会到达 Lambda**。写入端存储国家/城市/地区，90 天 TTL；读取端
服务[站点指标](../../metrics/)页面。每个 Lambda 有自己的最小权限角色；API 公开
但受来源限制（[为什么用 CloudFront？](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md#why-cloudfront){ target="_blank" rel="noopener" }）。

### Terraform — 控制平面

`terraform/ci` 创建按环境的 state 后端以及 GitHub Actions 用于构建和运行各栈的
OIDC 角色。**Bootstrap 是唯一带外步骤** — 一个 GitHub Actions 之外的 AWS 用户
用自己的 IAM 权限创建它们；任何工作流都不会使用密钥。实现细节见
[`terraform/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md){ target="_blank" rel="noopener" }。

## 交付模型

两条交付平面，各有自己的闸门：

| 平面 | 路径 | 闸门 |
|---|---|---|
| **内容** | `main` → staging · `v*` → pre-prod → 带闸门 Pages | `prod` 上必需审阅者 |
| **基础设施** | `main` → staging 自动 apply · `v*` → prod 仅 plan | 手动 `terraform apply` |

部署在正确 ref 的每次成功 CI 构建后运行
（[#20](https://github.com/mathewmusango/my-portfolio/pull/20){ target="_blank" rel="noopener" }
将 prod 拆分为 Pages + S3 并改用官方 Pages actions）。当构建产物与上次部署
字节相同时 staging 会**跳过** — 一种内容哈希标记方案，避免纯文档合并反复刷新
bucket（[#29](https://github.com/mathewmusango/my-portfolio/pull/29){ target="_blank" rel="noopener" }、
[#31](https://github.com/mathewmusango/my-portfolio/pull/31){ target="_blank" rel="noopener" }）。

## 开发工作流

- 仓库是**唯一事实来源** — 同一个 `docs/` 目录既构建本地站点也构建 CI。
- **只用容器** — `podman-compose up` 运行 MkDocs 开发服务器；无需本地 Python/venv。
- **本地 HTTPS** 通过每台机器的 [mkcert](https://github.com/FiloSottile/mkcert){ target="_blank" rel="noopener" } 根 CA — 与线上站点的 TLS 对齐。
- 开发容器还提供 `/health` 端点，供其自身的 healthcheck 使用。
- 本地检查与 CI 完全一致（`check-compose.yaml` + `scripts/check_changed.sh`）。

上手步骤见[仓库 README](https://github.com/mathewmusango/my-portfolio#getting-started){ target="_blank" rel="noopener" }。

## CI / CD

一个变更分四个阶段发布 — 每个阶段都记录在
[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }：

1. **Build** — 严格的 `mkdocs build`（坏链接、过期翻译和 CSS 不平衡都会使构建失败）、
   `pip-audit`，并在每次 push/PR 到 `main` 及每个 `v*` 标签时产出站点构建产物。
2. **检查** — 每个表面一个工作流（`checks-{shell,python,js,terraform,yml}`），
   各自按变更路径自门控
   （[skip-model, #17](https://github.com/mathewmusango/my-portfolio/pull/17){ target="_blank" rel="noopener" }）：
   未触及的表面**跳过并报告成功**，因此十个必需检查永远不会阻塞无关 PR。
3. **部署** — Build 成功后 `workflow_run`：`main` → staging，`v*` → pre-prod +
   带闸门的 prod（见[交付模型](#交付模型)）。
4. **发布与基础设施** — `v*` 标签创建带 CycloneDX SBOM 的 GitHub Release；每次
   基础设施变更 Terraform 都会 plan（apply 保持手动）；`toggle-env` /
   `invalidate-cloudfront` 是手动运维附加项。

检查名就是闸门名 — CI 报告 job 名（`ci-build`、`checks-python-ruff`、…），使分支
保护和 ruleset 要求的与真正运行的完全一致
（[#12](https://github.com/mathewmusango/my-portfolio/pull/12){ target="_blank" rel="noopener" }）。

## 治理

Ruleset 即代码，保护两个关键的 ref
（[`rulesets/`](https://github.com/mathewmusango/my-portfolio/tree/main/rulesets){ target="_blank" rel="noopener" }）：

| Ref | 保护 |
|---|---|
| `main` | 仅 PR：1 个审批、squash/rebase、过期评审作废、全部 10 项必需检查、禁止 force-push、**无绕过 — 包括所有者** |
| `v*` 标签 | 仅维护者创建；要求 `ci-build` 通过；创建后不可变 |

执行发生在 push 时且经过验证 — 拒绝记录与配置存放在 `rulesets/main.md` 和
`rulesets/tags.md` 中。PR 携带映射到精选集合的标签（`ci` · `infra` ·
`security` · `governance` · `dependencies`），并由第二个 GitHub 账户以普通协作者
身份评审 — 所有者不会合入任何未经批准的内容。Issue 模板强制七部分结构
（[#15](https://github.com/mathewmusango/my-portfolio/pull/15){ target="_blank" rel="noopener" }、
[#18](https://github.com/mathewmusango/my-portfolio/pull/18){ target="_blank" rel="noopener" }）。

## 安全

- **没有长期密钥** — 部署和 Terraform 通过 OIDC 承担 AWS 角色
  （[#22](https://github.com/mathewmusango/my-portfolio/pull/22){ target="_blank" rel="noopener" }
  扩展了对带环境 job 的信任）。
- **每个 job 最小权限** — 独立的 `-terraform` · `-deploy` · `-invalidate` ·
  `-toggle` 角色；prod 指标边缘按设计**没有** toggle 角色。
- **私有存储** — S3 bucket 从不公开；CloudFront 仅通过 OAC 服务。
- **来源限制 API** — 指标端点公开但限于配置的站点来源；WAF/VPC 可选（免费层优先姿态）。
- **依赖卫生** — [Dependabot](https://github.com/mathewmusango/my-portfolio/security/dependabot){ target="_blank" rel="noopener" }、
  每次构建 `pip-audit`、每次发布 CycloneDX SBOM、CI 中 Checkov。
- 报告政策：[SECURITY.md](https://github.com/mathewmusango/my-portfolio/blob/main/SECURITY.md){ target="_blank" rel="noopener" }。

## 真实事故与留下的教训

平台在生产环境中以极具教育意义的方式出过故障。每个事故都记录在
[CHANGELOG](https://github.com/mathewmusango/my-portfolio/blob/main/CHANGELOG.md){ target="_blank" rel="noopener" }
中：

| 事故 | 根因 | 修复 |
|---|---|---|
| **Staging 每个对象 403** | SSE-KMS 与 CloudFront OAC 不兼容（无 `kms:Decrypt`） | 回退到 AES256（[`aee25c6`](https://github.com/mathewmusango/my-portfolio/commit/aee25c6){ target="_blank" rel="noopener" }） |
| **多提交批次使 staging 过期** | 部署闸门只对比 `HEAD~1..HEAD` | 现在每次成功 CI 构建都会部署（[`1bf9bd9`](https://github.com/mathewmusango/my-portfolio/commit/1bf9bd9){ target="_blank" rel="noopener" }） |
| **纯文档合并反复刷新 bucket** | `s3 sync` 总是重新上传新解压的产物 | 内容哈希标记跳过（[#29](https://github.com/mathewmusango/my-portfolio/pull/29){ target="_blank" rel="noopener" }、[#31](https://github.com/mathewmusango/my-portfolio/pull/31){ target="_blank" rel="noopener" }） |
| **"Expected — waiting" 检查** | 必需检查名还没有任何运行报告过 | 先注册名称；再用 skip-model 按路径门控（[#12](https://github.com/mathewmusango/my-portfolio/pull/12){ target="_blank" rel="noopener" }、[#17](https://github.com/mathewmusango/my-portfolio/pull/17){ target="_blank" rel="noopener" }） |

每个事故的模式：一次真实故障、一次根治修复、以及防止复发的手册更新 — 正是本站
以[版本时间线](../../atlas/releases/)记录的同一个循环。

## 如何探索

- **[仓库 README](https://github.com/mathewmusango/my-portfolio/blob/main/README.md){ target="_blank" rel="noopener" }** — 系统视图：架构、本地运行。
- **[`terraform/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/terraform/README.md){ target="_blank" rel="noopener" }** — 基础设施实现与依据。
- **[`.github/workflows/README.md`](https://github.com/mathewmusango/my-portfolio/blob/main/.github/workflows/README.md){ target="_blank" rel="noopener" }** — 每个工作流、角色和运维附加项。
- **[`CONTRIBUTING.md`](https://github.com/mathewmusango/my-portfolio/blob/main/CONTRIBUTING.md){ target="_blank" rel="noopener" }** — 变更如何变成合并。
- **[站点图谱](../../atlas/)** — 版本时间线、标签和站点结构图。
- **[GitHub Actions](https://github.com/mathewmusango/my-portfolio/actions){ target="_blank" rel="noopener" }** — 实时流水线。

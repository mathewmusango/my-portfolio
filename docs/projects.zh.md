---
icon: material/rocket-launch
---

# 重点项目

## 云与迁移

<div class="proj-acc" markdown>

???+ note "领导企业云迁移"

    领导了客户基础设施从本地到 AWS 的迁移——一个可扩展、安全的云架构，并拥有真正的灾难恢复实践。

    !!! note "主要贡献"

        - 设计了 AWS 架构——VPC、**安全组**和**站点到站点 VPN**
        - 使用 **FortiGate** 防火墙加固了边界
        - 将**灾难恢复**策略作为设计的一部分来定义，而非事后补充

    !!! quote "经验教训"

        从第一天起就规划灾难恢复——事后补充是痛苦的。在迁移工作负载之前，先做好网络和安全设计。分批迁移，而不是一次性大迁移。

    <p class="proj-tags"><span class="proj-tag">AWS</span><span class="proj-tag">Security Groups</span><span class="proj-tag">Site-to-Site VPN</span><span class="proj-tag">FortiGate</span><span class="proj-tag">Disaster Recovery</span></p>

</div>

## 可观测性与监控

<div class="proj-acc" markdown>

??? note "设计企业可观测性平台"

    构建了覆盖200多台服务器的集中式可观测性——将指标、日志和追踪统一到一个运营视图，并配备可操作的告警和仪表板。

    !!! note "主要贡献"

        - 部署 **Prometheus + Grafana + Mimir** 用于指标，**Loki** 用于日志，**Tempo** 用于追踪
        - 使用 **OpenTelemetry** 标准化插桩
        - 构建了告警和 SLO——告警因合理原因触发，而非噪音
        - 增加了容量规划和性能分析工作流

    !!! quote "经验教训"

        统一的可观测性胜过一堆仪表板。告警必须可操作；SLO 比原始图表更重要。

    <p class="proj-tags"><span class="proj-tag">Prometheus</span><span class="proj-tag">Grafana</span><span class="proj-tag">Mimir</span><span class="proj-tag">Loki</span><span class="proj-tag">Tempo</span><span class="proj-tag">OpenTelemetry</span><span class="proj-tag">Alerting</span><span class="proj-tag">SLOs</span></p>

</div>

## 安全与弹性

<div class="proj-acc" markdown>

??? note "实现 PCI-DSS 合规"

    在企业环境中实施了 CIS 加固标准和内部安全策略，以满足 PCI-DSS 要求。

    !!! note "主要贡献"

        - 在服务器上应用 **CIS 基准**和基础设施加固
        - 增加了漏洞管理和安全监控（**Wazuh**）
        - 建立了策略执行和治理流程

    !!! quote "经验教训"

        合规是一个持续的过程，而不是一个项目。自动化和加固标准使其可持续。

    <p class="proj-tags"><span class="proj-tag">PCI-DSS</span><span class="proj-tag">CIS Benchmarks</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">Wazuh</span><span class="proj-tag">Vulnerability Management</span></p>

??? note "构建业务连续性与灾难恢复"

    使用 Veeam 实施了备份和灾难恢复策略——将虚拟机复制到灾难恢复站点并保留本地备份，且恢复流程经过实际演练。

    !!! note "主要贡献"

        - 部署 **Veeam Backup & Replication**——虚拟机复制到灾难恢复站点和本地备份
        - 构建并演练了恢复流程

    !!! quote "经验教训"

        没有恢复演练的备份只是希望。定期测试灾难恢复，否则需要时它不会起作用。

    <p class="proj-tags"><span class="proj-tag">Veeam</span><span class="proj-tag">Backup &amp; Replication</span><span class="proj-tag">Disaster Recovery</span><span class="proj-tag">Business Continuity</span></p>

</div>

## 平台工程

<div class="proj-acc" markdown>

??? note "DevSecOps 环境搭建"

    设计并运营了面向现代云原生工作负载的生产级 Kubernetes 平台——Cilium 网络（配合 Calico 和 MetalLB）、DirectPV/MinIO/NFS 存储和安全内建——并使用 GitLab CI/CD、Argo CD、Jenkins 和 SonarQube 创建了端到端的 DevSecOps 交付流水线，在每个阶段嵌入安全和 PCI-DSS 合规。

    !!! note "主要贡献"

        - 在 **Cilium** 上架构平台——配合 **Calico** 和 **MetalLB** 实现网络策略和负载均衡——以及 Gateway API、入口和 WireGuard 加密
        - 使用 **DirectPV、MinIO 和 NFS** 设计存储——为应用团队提供持久卷和存储类
        - 内建安全：RBAC、机密管理、CIS 加固、镜像扫描、准入控制
        - 使用 **IaC 和 GitOps** 自动化一切——供应、配置、部署、升级
        - 使用 **GitLab CI/CD 和 Jenkins** 构建 CI/CD，配合 **Argo CD** GitOps 部署
        - 使用 **Harbor 和 Artifactory** 集中管理制品；使用 **SonarQube** 作为质量门禁
        - 自动化测试（**Selenium**）、文档（**Kroki**）和安全监控（**Wazuh**）
        - 将 **PCI-DSS 合规**控制接入流水线

    !!! quote "经验教训"

        网络决策影响一切——Cilium 物有所值。存储是生产 Kubernetes 中最困难的部分。安全应该加速交付，而不是阻碍它——GitOps 让每次部署都可审计。

    <p class="proj-tags"><span class="proj-tag">Kubernetes</span><span class="proj-tag">Cilium</span><span class="proj-tag">Calico</span><span class="proj-tag">MetalLB</span><span class="proj-tag">Gateway API</span><span class="proj-tag">DirectPV</span><span class="proj-tag">MinIO</span><span class="proj-tag">NFS</span><span class="proj-tag">GitLab</span><span class="proj-tag">GitLab CI/CD</span><span class="proj-tag">Argo CD</span><span class="proj-tag">Jenkins</span><span class="proj-tag">Harbor</span><span class="proj-tag">Artifactory</span><span class="proj-tag">SonarQube</span><span class="proj-tag">Selenium</span><span class="proj-tag">Kroki</span><span class="proj-tag">Wazuh</span><span class="proj-tag">GitOps</span><span class="proj-tag">RBAC</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">PCI-DSS</span></p>

</div>

## 知识与协作

<div class="proj-acc" markdown>

??? note "企业协作平台"

    部署了 Wikimedia 实例，在整个组织内集中知识共享和协作，并进行了自定义安全和性能调优。

    !!! note "主要贡献"

        - 为组织部署并配置了 **Wikimedia**
        - 为环境定制了安全和性能设置

    !!! quote "经验教训"

        协作工具只有在人们采用时才能发挥作用——让它快速且安全，人们就会使用它。

    <p class="proj-tags"><span class="proj-tag">Wikimedia</span><span class="proj-tag">Linux</span></p>

</div>

---

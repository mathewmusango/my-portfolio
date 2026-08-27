<div class="proj-acc" markdown>

???+ note "DevSecOps 环境搭建"

    设计并运营了面向现代云原生工作负载的生产级 Kubernetes 平台——Cilium 网络（配合 Calico 和 MetalLB）、DirectPV/MinIO/NFS 存储和安全内建——并使用 GitLab CI/CD、Argo CD、Jenkins 和 SonarQube 创建了端到端的 DevSecOps 交付流水线，在每个阶段嵌入安全和 PCI-DSS 合规。

    !!! note "我的角色"

        **角色：** 平台工程负责人 — Kubernetes 与 DevSecOps
        **范围：** 生产级 Kubernetes 平台（网络 · 存储 · 安全）；端到端 CI/CD 流水线；PCI-DSS 控制
        **职责：** 架构 → 构建 → 运维
        **领导力：** 为应用团队交付平台与交付能力 — 基础设施、CI/CD 和安全即服务

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

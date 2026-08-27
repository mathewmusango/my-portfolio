<div class="proj-acc" markdown>

???+ note "设计企业可观测性平台"

    构建了覆盖200多台服务器的集中式可观测性——将指标、日志和追踪统一到一个运营视图，并配备可操作的告警和仪表板。

    !!! note "我的角色"

        **角色：** 平台工程负责人 — 可观测性
        **范围：** 覆盖 200+ 台服务器的平台架构；技术栈选型（Prometheus · Grafana · Mimir · Loki · Tempo · OpenTelemetry）；告警与 SLO
        **职责：** 架构 → 部署 → 运维落地

    !!! note "主要贡献"

        - 部署 **Prometheus + Grafana + Mimir** 用于指标，**Loki** 用于日志，**Tempo** 用于追踪
        - 使用 **OpenTelemetry** 标准化插桩
        - 构建了告警和 SLO——告警因合理原因触发，而非噪音
        - 增加了容量规划和性能分析工作流

    !!! quote "经验教训"

        统一的可观测性胜过一堆仪表板。告警必须可操作；SLO 比原始图表更重要。

    <p class="proj-tags"><span class="proj-tag">Prometheus</span><span class="proj-tag">Grafana</span><span class="proj-tag">Mimir</span><span class="proj-tag">Loki</span><span class="proj-tag">Tempo</span><span class="proj-tag">OpenTelemetry</span><span class="proj-tag">Alerting</span><span class="proj-tag">SLOs</span></p>

</div>

---
icon: material/rocket-launch
---

# Key Projects

## Cloud & Migrations

<div class="proj-acc" markdown>

???+ note "Leading an Enterprise Cloud Migration"

    Led the migration of client infrastructure from on-premises to AWS — a scalable, secure cloud architecture with a real disaster recovery story.

    !!! note "Key Contributions"

        - Designed the AWS architecture — VPC, **Security Groups**, and a **Site-to-Site VPN**
        - Hardened the perimeter with **FortiGate** firewall
        - Defined the **disaster recovery** strategy as part of the design, not after

    !!! quote "Lessons Learned"

        Plan DR from day one — retrofitting it is painful. Get network and security design right before moving workloads. Migrate in waves, not big bangs.

    <p class="proj-tags"><span class="proj-tag">AWS</span><span class="proj-tag">Security Groups</span><span class="proj-tag">Site-to-Site VPN</span><span class="proj-tag">FortiGate</span><span class="proj-tag">Disaster Recovery</span></p>

</div>

## Observability & Monitoring

<div class="proj-acc" markdown>

??? note "Designing an Enterprise Observability Platform"

    Built centralized observability across 200+ servers — unifying metrics, logs, and traces into a single operational view with actionable alerting and dashboards.

    !!! note "Key Contributions"

        - Deployed **Prometheus + Grafana + Mimir** for metrics, **Loki** for logs, **Tempo** for tracing
        - Standardized on **OpenTelemetry** for instrumentation
        - Built alerting and SLOs — alerts that fire for a reason, not noise
        - Added capacity planning and performance analysis workflows

    !!! quote "Lessons Learned"

        Unified observability beats a pile of dashboards. Alerts must be actionable; SLOs matter more than raw graphs.

    <p class="proj-tags"><span class="proj-tag">Prometheus</span><span class="proj-tag">Grafana</span><span class="proj-tag">Mimir</span><span class="proj-tag">Loki</span><span class="proj-tag">Tempo</span><span class="proj-tag">OpenTelemetry</span><span class="proj-tag">Alerting</span><span class="proj-tag">SLOs</span></p>

</div>

## Security & Resilience

<div class="proj-acc" markdown>

??? note "Achieving PCI-DSS Compliance"

    Implemented CIS hardening standards and internal security policies to meet PCI-DSS requirements across enterprise environments.

    !!! note "Key Contributions"

        - Applied **CIS benchmarks** and infrastructure hardening across servers
        - Added vulnerability management and security monitoring (**Wazuh**)
        - Established policy enforcement and governance processes

    !!! quote "Lessons Learned"

        Compliance is a continuous process, not a project. Automation and hardening standards make it sustainable.

    <p class="proj-tags"><span class="proj-tag">PCI-DSS</span><span class="proj-tag">CIS Benchmarks</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">Wazuh</span><span class="proj-tag">Vulnerability Management</span></p>

??? note "Building Business Continuity & Disaster Recovery"

    Implemented a backup and DR strategy with Veeam — replicating virtual machines to a DR site plus on-site backups, with recovery that is actually tested.

    !!! note "Key Contributions"

        - Deployed **Veeam Backup & Replication** — VM replication to DR and on-site backups
        - Built and exercised recovery procedures

    !!! quote "Lessons Learned"

        Backups without restore tests are just hope. Test your DR regularly or it won't work when you need it.

    <p class="proj-tags"><span class="proj-tag">Veeam</span><span class="proj-tag">Backup &amp; Replication</span><span class="proj-tag">Disaster Recovery</span><span class="proj-tag">Business Continuity</span></p>

</div>

## Platform Engineering

<div class="proj-acc" markdown>

??? note "DevSecOps Environment Setup"

    Designed and operated a production-grade Kubernetes platform for modern cloud-native workloads — Cilium networking (with Calico and MetalLB in place), DirectPV/MinIO/NFS storage, and security built in — and created an end-to-end DevSecOps delivery pipeline with GitLab CI/CD, Argo CD, Jenkins, and SonarQube, embedding security and PCI-DSS compliance at every stage.

    !!! note "Key Contributions"

        - Architected the platform on **Cilium** — with **Calico** and **MetalLB** in place for network policies and load balancing — plus Gateway API, ingress, and WireGuard encryption
        - Designed storage with **DirectPV, MinIO, and NFS** — persistent volumes and storage classes for application teams
        - Embedded security: RBAC, secrets management, CIS hardening, image scanning, admission controls
        - Automated everything with **IaC and GitOps** — provisioning, configuration, deployments, upgrades
        - Built CI/CD on **GitLab CI/CD and Jenkins** with **Argo CD** GitOps deployments
        - Centralized artifacts with **Harbor and Artifactory**; quality gates with **SonarQube**
        - Automated testing (**Selenium**), docs (**Kroki**), and security monitoring (**Wazuh**)
        - Wired **PCI-DSS compliance** controls into the pipeline

    !!! quote "Lessons Learned"

        Networking decisions shape everything — Cilium paid off. Storage is the hardest part of production Kubernetes. Security should accelerate delivery, not gate it — GitOps makes every deployment auditable.

    <p class="proj-tags"><span class="proj-tag">Kubernetes</span><span class="proj-tag">Cilium</span><span class="proj-tag">Calico</span><span class="proj-tag">MetalLB</span><span class="proj-tag">Gateway API</span><span class="proj-tag">DirectPV</span><span class="proj-tag">MinIO</span><span class="proj-tag">NFS</span><span class="proj-tag">GitLab</span><span class="proj-tag">GitLab CI/CD</span><span class="proj-tag">Argo CD</span><span class="proj-tag">Jenkins</span><span class="proj-tag">Harbor</span><span class="proj-tag">Artifactory</span><span class="proj-tag">SonarQube</span><span class="proj-tag">Selenium</span><span class="proj-tag">Kroki</span><span class="proj-tag">Wazuh</span><span class="proj-tag">GitOps</span><span class="proj-tag">RBAC</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">PCI-DSS</span></p>

</div>

## Knowledge & Collaboration

<div class="proj-acc" markdown>

??? note "Enterprise Collaboration Platform"

    Deployed a Wikimedia instance to centralize knowledge sharing and collaboration across the organization, with custom security and performance tuning.

    !!! note "Key Contributions"

        - Deployed and configured **Wikimedia** for the organization
        - Customized security and performance settings for the environment

    !!! quote "Lessons Learned"

        A collaboration tool only works when people adopt it — making it fast and secure gets them there.

    <p class="proj-tags"><span class="proj-tag">Wikimedia</span><span class="proj-tag">Linux</span></p>

</div>

---

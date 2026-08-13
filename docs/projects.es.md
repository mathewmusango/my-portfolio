---
icon: material/rocket-launch
---

# Proyectos Clave

## Nube y Migraciones

<div class="proj-acc" markdown>

???+ note "Liderando una Migración Empresarial a la Nube"

    Lideré la migración de la infraestructura de clientes de on-premises a AWS — una arquitectura de nube escalable y segura con una historia real de recuperación ante desastres.

    !!! note "Contribuciones Clave"

        - Diseñé la arquitectura AWS — VPC, **Security Groups** y una **VPN Site-to-Site**
        - Endurecí el perímetro con el firewall **FortiGate**
        - Definí la estrategia de **recuperación ante desastres** como parte del diseño, no después

    !!! quote "Lecciones Aprendidas"

        Planifica la recuperación ante desastres desde el primer día — adaptarla después es doloroso. Diseña bien la red y la seguridad antes de mover cargas de trabajo. Migra por oleadas, no de golpe.

    <p class="proj-tags"><span class="proj-tag">AWS</span><span class="proj-tag">Security Groups</span><span class="proj-tag">Site-to-Site VPN</span><span class="proj-tag">FortiGate</span><span class="proj-tag">Disaster Recovery</span></p>

</div>

## Observabilidad y Monitoreo

<div class="proj-acc" markdown>

??? note "Diseñando una Plataforma Empresarial de Observabilidad"

    Construí observabilidad centralizada en más de 200 servidores — unificando métricas, logs y trazas en una única vista operativa con alertas accionables y paneles.

    !!! note "Contribuciones Clave"

        - Desplegué **Prometheus + Grafana + Mimir** para métricas, **Loki** para logs, **Tempo** para trazabilidad
        - Estandarice con **OpenTelemetry** para la instrumentación
        - Construí alertas y SLOs — alertas que se activan por una razón, no por ruido
        - Agregué flujos de trabajo de planificación de capacidad y análisis de rendimiento

    !!! quote "Lecciones Aprendidas"

        La observabilidad unificada supera a un montón de paneles. Las alertas deben ser accionables; los SLOs importan más que los gráficos en bruto.

    <p class="proj-tags"><span class="proj-tag">Prometheus</span><span class="proj-tag">Grafana</span><span class="proj-tag">Mimir</span><span class="proj-tag">Loki</span><span class="proj-tag">Tempo</span><span class="proj-tag">OpenTelemetry</span><span class="proj-tag">Alerting</span><span class="proj-tag">SLOs</span></p>

</div>

## Seguridad y Resiliencia

<div class="proj-acc" markdown>

??? note "Logrando Cumplimiento PCI-DSS"

    Implementé estándares de endurecimiento CIS y políticas de seguridad internas para cumplir los requisitos PCI-DSS en entornos empresariales.

    !!! note "Contribuciones Clave"

        - Apliqué **benchmarks CIS** y endurecimiento de infraestructura en servidores
        - Agregué gestión de vulnerabilidades y monitoreo de seguridad (**Wazuh**)
        - Establecí procesos de aplicación de políticas y gobernanza

    !!! quote "Lecciones Aprendidas"

        El cumplimiento es un proceso continuo, no un proyecto. La automatización y los estándares de endurecimiento lo hacen sostenible.

    <p class="proj-tags"><span class="proj-tag">PCI-DSS</span><span class="proj-tag">CIS Benchmarks</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">Wazuh</span><span class="proj-tag">Vulnerability Management</span></p>

??? note "Construyendo Continuidad del Negocio y Recuperación ante Desastres"

    Implementé una estrategia de respaldo y DR con Veeam — replicando máquinas virtuales a un sitio de DR más respaldos en sitio, con una recuperación realmente probada.

    !!! note "Contribuciones Clave"

        - Desplegué **Veeam Backup & Replication** — replicación de VM a DR y respaldos en sitio
        - Construí y ejercité los procedimientos de recuperación

    !!! quote "Lecciones Aprendidas"

        Los respaldos sin pruebas de restauración son solo esperanza. Prueba tu DR regularmente o no funcionará cuando lo necesites.

    <p class="proj-tags"><span class="proj-tag">Veeam</span><span class="proj-tag">Backup &amp; Replication</span><span class="proj-tag">Disaster Recovery</span><span class="proj-tag">Business Continuity</span></p>

</div>

## Ingeniería de Plataformas

<div class="proj-acc" markdown>

??? note "Configuración del Entorno DevSecOps"

    Diseñé y operé una plataforma Kubernetes de grado de producción para cargas de trabajo cloud-native modernas — red Cilium (con Calico y MetalLB en su lugar), almacenamiento DirectPV/MinIO/NFS y seguridad integrada — y creé un pipeline de entrega DevSecOps de extremo a extremo con GitLab CI/CD, Argo CD, Jenkins y SonarQube, integrando seguridad y cumplimiento PCI-DSS en cada etapa.

    !!! note "Contribuciones Clave"

        - Arquitecté la plataforma sobre **Cilium** — con **Calico** y **MetalLB** para políticas de red y balanceo de carga — además de Gateway API, ingress y cifrado WireGuard
        - Diseñé almacenamiento con **DirectPV, MinIO y NFS** — volúmenes persistentes y clases de almacenamiento para los equipos de aplicación
        - Integré seguridad: RBAC, gestión de secretos, endurecimiento CIS, escaneo de imágenes, controles de admisión
        - Automatice todo con **IaC y GitOps** — aprovisionamiento, configuración, despliegues, actualizaciones
        - Construí CI/CD con **GitLab CI/CD y Jenkins** con despliegues GitOps de **Argo CD**
        - Centralice artefactos con **Harbor y Artifactory**; puertas de calidad con **SonarQube**
        - Automatice pruebas (**Selenium**), documentación (**Kroki**) y monitoreo de seguridad (**Wazuh**)
        - Integré controles de **cumplimiento PCI-DSS** en el pipeline

    !!! quote "Lecciones Aprendidas"

        Las decisiones de red moldean todo — Cilium valió la pena. El almacenamiento es la parte más difícil del Kubernetes de producción. La seguridad debería acelerar la entrega, no bloquearla — GitOps hace auditable cada despliegue.

    <p class="proj-tags"><span class="proj-tag">Kubernetes</span><span class="proj-tag">Cilium</span><span class="proj-tag">Calico</span><span class="proj-tag">MetalLB</span><span class="proj-tag">Gateway API</span><span class="proj-tag">DirectPV</span><span class="proj-tag">MinIO</span><span class="proj-tag">NFS</span><span class="proj-tag">GitLab</span><span class="proj-tag">GitLab CI/CD</span><span class="proj-tag">Argo CD</span><span class="proj-tag">Jenkins</span><span class="proj-tag">Harbor</span><span class="proj-tag">Artifactory</span><span class="proj-tag">SonarQube</span><span class="proj-tag">Selenium</span><span class="proj-tag">Kroki</span><span class="proj-tag">Wazuh</span><span class="proj-tag">GitOps</span><span class="proj-tag">RBAC</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">PCI-DSS</span></p>

</div>

## Conocimiento y Colaboración

<div class="proj-acc" markdown>

??? note "Plataforma Empresarial de Colaboración"

    Desplegué una instancia de Wikimedia para centralizar el intercambio de conocimiento y la colaboración en toda la organización, con seguridad personalizada y ajuste de rendimiento.

    !!! note "Contribuciones Clave"

        - Desplegué y configuré **Wikimedia** para la organización
        - Personalice la seguridad y el rendimiento para el entorno

    !!! quote "Lecciones Aprendidas"

        Una herramienta de colaboración solo funciona cuando la gente la adopta — hacerla rápida y segura los lleva hasta allí.

    <p class="proj-tags"><span class="proj-tag">Wikimedia</span><span class="proj-tag">Linux</span></p>

</div>

---

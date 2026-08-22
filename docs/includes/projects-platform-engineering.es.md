<div class="proj-acc" markdown>

???+ note "Configuración del Entorno DevSecOps"

    Diseñé y operé una plataforma Kubernetes de grado de producción para cargas de trabajo cloud-native modernas — red Cilium (con Calico y MetalLB en su lugar), almacenamiento DirectPV/MinIO/NFS y seguridad integrada — y creé un pipeline de entrega DevSecOps de extremo a extremo con GitLab CI/CD, Argo CD, Jenkins y SonarQube, integrando seguridad y cumplimiento PCI-DSS en cada etapa.

    !!! note "Contribuciones Clave"

        - Arquitecté la plataforma sobre **Cilium** — con **Calico** y **MetalLB** para políticas de red y balanceo de carga — además de Gateway API, ingress y cifrado WireGuard
        - Diseñé almacenamiento con **DirectPV, MinIO y NFS** — volúmenes persistentes y clases de almacenamiento para los equipos de aplicación
        - Integré seguridad: RBAC, gestión de secretos, endurecimiento CIS, escaneo de imágenes, controles de admisión
        - Automatiqué todo con **IaC y GitOps** — aprovisionamiento, configuración, despliegues, actualizaciones
        - Construí CI/CD con **GitLab CI/CD y Jenkins** con despliegues GitOps de **Argo CD**
        - Centralicé artefactos con **Harbor y Artifactory**; puertas de calidad con **SonarQube**
        - Automatiqué pruebas (**Selenium**), documentación (**Kroki**) y monitoreo de seguridad (**Wazuh**)
        - Integré controles de **cumplimiento PCI-DSS** en el pipeline

    !!! quote "Lecciones Aprendidas"

        Las decisiones de red moldean todo — Cilium valió la pena. El almacenamiento es la parte más difícil del Kubernetes de producción. La seguridad debería acelerar la entrega, no bloquearla — GitOps hace auditable cada despliegue.

    <p class="proj-tags"><span class="proj-tag">Kubernetes</span><span class="proj-tag">Cilium</span><span class="proj-tag">Calico</span><span class="proj-tag">MetalLB</span><span class="proj-tag">Gateway API</span><span class="proj-tag">DirectPV</span><span class="proj-tag">MinIO</span><span class="proj-tag">NFS</span><span class="proj-tag">GitLab</span><span class="proj-tag">GitLab CI/CD</span><span class="proj-tag">Argo CD</span><span class="proj-tag">Jenkins</span><span class="proj-tag">Harbor</span><span class="proj-tag">Artifactory</span><span class="proj-tag">SonarQube</span><span class="proj-tag">Selenium</span><span class="proj-tag">Kroki</span><span class="proj-tag">Wazuh</span><span class="proj-tag">GitOps</span><span class="proj-tag">RBAC</span><span class="proj-tag">CIS Hardening</span><span class="proj-tag">PCI-DSS</span></p>

</div>

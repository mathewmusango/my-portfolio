# Security Policy

This repository is a static portfolio site, plus the Terraform that provisions the infrastructure it runs on and the CI that deploys it.

If something here should not be public or you find a security issue, use **Security → Report a vulnerability**, or [email](mailto:musangomathew@gmail.com).

## Dependency remediation

The audit gate blocks a merge that introduces a **high** or **critical** advisory
(`pip-audit` on `requirements.txt`, `npm audit --audit-level=high` on the lockfile), so nothing
lands with a known high finding. What the gate cannot see is an advisory published *after* a
dependency was merged, which is what the windows below cover:

| Severity | Fix within |
| --- | --- |
| Critical | 7 days |
| High | 30 days |
| Moderate | 90 days |
| Low | next dependency refresh |

`CI: Dependency SLA` runs weekly and fails when an open Dependabot alert is older than its
window, naming the package, the age and the alert link. An advisory with no fixed release is
not a reason to wait: the window still applies, and the dependency is replaced, pinned back, or
an exception is written in the pull request that keeps it.

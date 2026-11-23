# terraform

| Root | State key | Owns |
| --- | --- | --- |
| `bootstrap/` | `ci/terraform.tfstate` | state backends, the OIDC provider and the per-job roles — run once, by a person |
| `infra/site/` | `site/terraform.tfstate` | the private bucket, the distribution and its headers policy |
| `infra/metrics/` | `metrics/terraform.tfstate` | API Gateway, the writer/reader Lambdas, DynamoDB, its own edge |

`modules/` holds the generic per-service leaves the roots compose.

A push to `main` applies staging; a `v*` tag applies prod behind the `prod` reviewer, and only if
the tag points at a commit on `main`. No workflow holds a key — each job assumes its own OIDC role.

Free Tier only: private buckets behind CloudFront with OAC, `prevent_destroy` on the stateful
resources, no IP stored by the analytics (CloudFront supplies the geo headers, events expire after
90 days). `local.tfvars` points the metrics root at MiniStack for local work.

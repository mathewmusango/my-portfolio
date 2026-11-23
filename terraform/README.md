# terraform

The AWS behind the site, in three roots that are applied independently.

| Root | State key | What it owns |
| --- | --- | --- |
| `bootstrap/` | `ci/terraform.tfstate` | the state backends, the OIDC provider and the per-job roles — run once, by a person, with an AWS user |
| `infra/site/` | `site/terraform.tfstate` | the private S3 bucket, the CloudFront distribution and its response-headers policy |
| `infra/metrics/` | `metrics/terraform.tfstate` | the visitor analytics: API Gateway, writer/reader Lambdas, DynamoDB, its own distribution and headers policy |

`modules/` holds the per-service leaves (`s3`, `cloudfront`, `dynamodb`, `lambda`, `api-gateway`,
`iam`, `vpc`, `waf`) the roots compose. The two composites keep portfolio vocabulary; the leaves
are generic and reusable.

## Deploy

`terraform.yml` runs on `terraform/**` changes: a push to `main` applies **staging**, a `v*` tag
applies **prod** behind the `prod` environment's reviewer, and a dispatch can plan only or target
one root with `stack`. A prod run must come from a tag that points at a commit on `main`.

No workflow holds a key. Each job assumes its own role through OIDC — `-terraform`, `-deploy`,
`-invalidate`, `-toggle` — and staging cannot read prod's role, because the ARN lives in the
environment the job declares.

## Security posture

Free Tier only: no WAF, no interface endpoints, no customer-managed keys on the critical path.
Buckets are private and served through CloudFront with OAC; the site bucket, both distributions
and the metrics table carry `prevent_destroy`, and the metrics table and the lock table refuse
deletion at the AWS API as well. The metrics API is public but origin-gated — CloudFront supplies
the geo headers, so no IP address reaches a Lambda, and raw events expire after 90 days.

## Why CloudFront?

It is the only edge that hands a Lambda the visitor's country without the IP: the geo headers are
set at the edge and the request arrives without the address. That is what makes the analytics
privacy-first rather than policy-first.

## Local work

`terraform/local.tfvars` points the metrics root at MiniStack — an AWS-compatible emulator — with
`environment = "test"`. Everything else is exercised through the same roots CI applies; the checks
(`fmt`, `validate`, TFLint, Checkov) run in `CI: Checks` and `CI: Security`.

State and secrets are never committed. `.terraform.lock.hcl` files are, and a provider bump moves
them through a pull request.

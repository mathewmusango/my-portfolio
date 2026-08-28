plugin "aws" {
  enabled = true
  version = "0.34.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Tune these as findings surface — the repo was retrofitted (audit backlog on
# iam:PassRole scope, site-bucket versioning, WAF/VPC opt-ins, ...).

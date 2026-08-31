# Local dev overrides (explicit -var-file — NOT auto-loaded, so real-AWS deploys
# are unaffected). Credentials, region, and the Ministack endpoint come from
# ~/.aws/config + ~/.aws/credentials automatically — nothing AWS-related lives
# in this repo.
#
# Ministack vs real AWS is a VARIABLES-only difference (same code):
#   environment / allowed_origin / enable_vpc / enable_waf / enable_cloudfront
environment    = "test"
# Both local https origins pass the gate — the dev domain (after /etc/hosts)
# and plain localhost (works before any hosts entry exists).
allowed_origin = "https://portfolio.mathewmusango.test:8000,https://localhost:8000"

# Required deployment values (no defaults in variables.tf — real AWS gets them
# from CI secrets, never from code). These local values are test-only:
# project/aws_region/tags + environment + allowed_origin.
project    = "my-portfolio"
aws_region = "us-east-1"
tags = {
  project    = "my-portfolio"
  managed_by = "terraform"
  repo       = "mathewmusango/my-portfolio"
}

# Feature flags — mirror staging/prod exactly (see terraform.yml plan step):
# VPC + WAF stay OFF (Free Tier; no real VPC/WAF on Ministack), the metrics
# stack + site + CloudFront are ON (Ministack implements the CF management
# plane; geo headers are just "unknown" locally — no real edge).
enable_vpc        = false
enable_waf        = false
enable_cloudfront = true
enable_metrics    = true
enable_site       = true

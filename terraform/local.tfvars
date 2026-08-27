# Local dev overrides (explicit -var-file — NOT auto-loaded, so real-AWS deploys
# are unaffected). Credentials, region, and the Ministack endpoint come from
# ~/.aws/config + ~/.aws/credentials automatically — nothing AWS-related lives
# in this repo.
#
# Ministack vs real AWS is a VARIABLES-only difference (same code):
#   environment / allowed_origin / enable_vpc / enable_waf / enable_cloudfront
environment    = "test"
allowed_origin = "http://localhost:8000"
# Ministack has no real VPC, WAF, or CloudFront — the lambda origin gate still
# applies. Real AWS keeps VPC/WAF/CloudFront OFF by default (Free Tier) except
# CloudFront, which is ON (the workflow passes the flags explicitly).
enable_vpc        = false
enable_waf        = false
enable_cloudfront = false

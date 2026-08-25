# Local dev overrides (explicit -var-file — NOT auto-loaded, so real-AWS deploys
# are unaffected). Credentials, region, and the Ministack endpoint come from
# ~/.aws/config + ~/.aws/credentials automatically — nothing AWS-related lives
# in this repo.
environment    = "test"
allowed_origin = "http://localhost:8000"
# Ministack has no real VPC or WAF — the lambda origin gate still applies.
enable_vpc     = false
enable_waf     = false

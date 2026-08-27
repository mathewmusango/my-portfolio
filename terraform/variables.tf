variable "aws_region" {
  description = "AWS region for the metrics stack (CloudFront is global regardless). Deployment value — supplied via TF_VAR_aws_region / -var (CI secret), never hardcoded."
  type        = string
}

variable "project" {
  description = "Project name — prefixes all resource names."
  type        = string
  default     = "my-portfolio"
}

variable "environment" {
  description = "Environment tag/suffix (prod/test). The live site metrics stack is 'prod'."
  type        = string
  default     = "prod"
}

variable "allowed_origin" {
  description = "CORS origin for the metrics API — the site that sends events. Deployment value — supplied via -var (repo variable), never hardcoded."
  type        = string
}

variable "event_retention_days" {
  description = "DynamoDB TTL — raw events are deleted after this many days."
  type        = number
  default     = 90
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100/200/All). All = global edge coverage."
  type        = string
  default     = "PriceClass_All"
}

variable "enable_cloudfront" {
  description = "Create the CloudFront distribution + geo origin-request policy. On by default (real AWS); works on Ministack too. Geo headers only exist behind real CloudFront."
  type        = bool
  default     = true
}

variable "enable_vpc" {
  description = "Run the Lambdas inside a private VPC (real AWS) — no internet path, only VPC endpoints for DynamoDB + CloudWatch Logs. OFF by default: the VPC's CloudWatch Logs interface endpoint (~$7/mo) is outside the Free Tier; the Lambda origin gate + least-privilege IAM still apply. Opt in for the hardened variant (also disable for Ministack, which has no real VPC)."
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Attach a WAF ACL to the CloudFront distribution (real AWS only): allow only the site's Origin/Referer + rate-limit rule. OFF by default: WAF (~$7/mo) is outside the Free Tier; the Lambda origin gate (403 for non-site origins) is the free equivalent. Opt in for the hardened variant (also disable for Ministack)."
  type        = bool
  default     = false
}

variable "waf_allowed_host" {
  description = "Host that WAF allows through (Origin/Referer) — must match the site origin."
  type        = string
  default     = "mathewmusango.github.io"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    project    = "my-portfolio"
    managed_by = "terraform"
    repo       = "mathewmusango/my-portfolio"
  }
}

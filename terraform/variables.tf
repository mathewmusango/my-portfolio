variable "aws_region" {
  description = "AWS region for the metrics stack (CloudFront is global regardless)."
  type        = string
  default     = "us-east-1"
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
  description = "CORS origin for the metrics API — the site that sends events."
  type        = string
  default     = "https://mathewmusango.github.io"
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
  description = "Run the Lambdas inside a private VPC (real AWS) — no internet path, only VPC endpoints for DynamoDB + CloudWatch Logs. Disable for Ministack (no real VPC)."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach a WAF ACL to the CloudFront distribution (real AWS only): allow only the site's Origin/Referer + rate-limit rule. Disable for Ministack."
  type        = bool
  default     = true
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
    repo       = "kizingainc/my-portfolio"
  }
}

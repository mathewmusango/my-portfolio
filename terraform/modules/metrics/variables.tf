variable "aws_region" {
  description = "AWS region for the metrics stack (CloudFront is global regardless)."
  type        = string
}

variable "project" {
  description = "Project name — prefixes all resource names."
  type        = string
}

variable "environment" {
  description = "Environment label (staging|prod)."
  type        = string
}

variable "allowed_origin" {
  description = "CORS origin for the metrics API — the site that sends events."
  type        = string
}

variable "event_retention_days" {
  description = "DynamoDB TTL — raw events are deleted after this many days."
  type        = number
  default     = 90
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100/200/All)."
  type        = string
  default     = "PriceClass_All"
}

variable "enable_cloudfront" {
  description = "Create the CloudFront distribution + geo origin-request policy."
  type        = bool
  default     = true
}

variable "enable_vpc" {
  description = "Run the Lambdas inside a private VPC (real AWS). OFF by default (Free Tier)."
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Attach a WAF ACL to the metrics CloudFront distribution. OFF by default (Free Tier)."
  type        = bool
  default     = false
}

variable "waf_allowed_host" {
  description = "Host that WAF allows through (Origin/Referer)."
  type        = string
  default     = ""
}

variable "tags" {
  type = map(string)
}

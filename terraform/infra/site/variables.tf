variable "aws_region" {
  description = "AWS region (CloudFront is global regardless). Deployment value — supplied via TF_VAR_aws_region / -var, never hardcoded."
  type        = string
}

variable "project" {
  description = "Project name — prefixes all resource names. Supplied via -var, never hardcoded."
  type        = string
}

variable "environment" {
  description = "Environment label (staging|prod) — suffix for all resource names. Supplied via -var (trigger-resolved), never hardcoded."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources. Supplied via -var, never hardcoded."
  type        = map(string)
}

variable "enable_site" {
  description = "Deploy the site: private S3 bucket + CloudFront via OAC."
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100/200/All)."
  type        = string
  default     = "PriceClass_All"
}

variable "project" {
  description = "Project name — prefixes all resource names."
  type        = string
}

variable "environment" {
  description = "Environment label (staging|prod) — suffix for all resource names."
  type        = string
}

variable "tags" {
  description = "Base tags applied to every taggable resource."
  type        = map(string)
}

variable "enable_site" {
  description = "Deploy the site: private S3 bucket + CloudFront via OAC."
  type        = bool
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100/200/All)."
  type        = string
}

variable "response_headers_policy_id" {
  description = "Security-headers policy applied to the distribution (owned by the root — both products attach it)."
  type        = string
}

variable "name" {
  description = "Distribution comment and origin id."
  type        = string
}

variable "oac_name" {
  description = "Origin access control name."
  type        = string
}

variable "tags" {
  description = "Tags applied to the distribution."
  type        = map(string)
}

variable "enable" {
  description = "Create the OAC, distribution, functions and OAC bucket policy."
  type        = bool
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100/200/All)."
  type        = string
}

variable "origin_bucket_id" {
  description = "Origin S3 bucket id (bucket policy target)."
  type        = string
}

variable "origin_bucket_arn" {
  description = "Origin S3 bucket ARN (OAC policy resource)."
  type        = string
}

variable "origin_bucket_regional_domain_name" {
  description = "Origin S3 bucket regional domain name."
  type        = string
}

variable "default_root_object" {
  description = "Object served for the root path."
  type        = string
  default     = "index.html"
}

variable "cache_policy_id" {
  description = "Managed cache policy id for the default cache behavior."
  type        = string
}

variable "response_headers_policy_id" {
  description = "Security-headers policy applied to the distribution."
  type        = string
}

variable "allowed_methods" {
  description = "HTTP methods allowed by the default cache behavior."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cached_methods" {
  description = "HTTP methods cached by the default cache behavior."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "functions" {
  description = "CloudFront Functions and their viewer associations, keyed by key."
  type = list(object({
    key        = string
    name       = string
    comment    = string
    code       = string
    event_type = string
  }))
  default = []
}

variable "error_responses" {
  description = "Custom error responses."
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = []
}

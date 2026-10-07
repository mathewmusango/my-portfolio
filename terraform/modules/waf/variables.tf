variable "name" {
  description = "Web ACL name."
  type        = string
}

variable "tags" {
  description = "Tags applied to the web ACL."
  type        = map(string)
}

variable "enable" {
  description = "Create the web ACL and its association."
  type        = bool
}

variable "scope" {
  description = "Web ACL scope (CLOUDFRONT or REGIONAL)."
  type        = string
  default     = "CLOUDFRONT"
}

variable "allowed_host" {
  description = "Host permitted to reach the edge (Origin/Referer match)."
  type        = string
}

variable "rate_limit" {
  description = "Requests per five minutes per IP before blocking."
  type        = number
  default     = 300
}

variable "metric_name" {
  description = "CloudWatch metric name for the web ACL."
  type        = string
  default     = "waf"
}

variable "association_arn" {
  description = "Resource ARN the ACL is associated with (required when enabled)."
  type        = string
  default     = null
}

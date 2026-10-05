variable "name" {
  description = "HTTP API name."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

variable "cors" {
  description = "CORS configuration."
  type = object({
    allow_origins = list(string)
    allow_methods = list(string)
    allow_headers = list(string)
    max_age       = number
  })
}

variable "integrations" {
  description = "Lambda integrations, keyed by a stable name."
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
  }))
}

variable "routes" {
  description = "Routes, keyed by a stable name; integration_key selects the integration."
  type = map(object({
    route_key       = string
    integration_key = string
  }))
}

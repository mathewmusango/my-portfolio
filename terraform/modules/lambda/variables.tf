variable "function_name" {
  description = "Lambda function name."
  type        = string
}

variable "role_name" {
  description = "IAM role name."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

variable "handler" {
  description = "Function handler."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "filename" {
  description = "Path to the deployment package."
  type        = string
}

variable "source_code_hash" {
  description = "Base64 SHA-256 of the deployment package (redeploys on change)."
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Function memory in MB."
  type        = number
  default     = 128
}

variable "environment" {
  description = "Environment variables."
  type        = map(string)
  default     = {}
}

variable "iam_policies" {
  description = "Inline IAM policies to attach to the role, keyed by a stable name."
  type = map(object({
    name   = string
    policy = string
  }))
  default = {}
}

variable "enable_vpc" {
  description = "Run the function inside a VPC."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet ids for the VPC config."
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Security group id for the VPC config."
  type        = string
  default     = null
}

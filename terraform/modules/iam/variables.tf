variable "role_name" {
  description = "IAM role name."
  type        = string
}

variable "assume_role_policy" {
  description = "JSON trust policy for the role."
  type        = string
}

variable "tags" {
  description = "Tags applied to the role and its policies."
  type        = map(string)
}

variable "managed_policy_arns" {
  description = "AWS-managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Inline policies to create and attach, keyed by a stable name."
  type = map(object({
    name   = string
    policy = string
  }))
  default = {}
}

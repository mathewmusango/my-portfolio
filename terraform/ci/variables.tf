variable "aws_region" {
  description = "Region for the state bucket + lock table (the OIDC provider and role are global). Supplied from .env / CI secret — never hardcoded."
  type        = string
}

variable "environment" {
  description = "Environment label (staging|prod) — suffixed into account-global names (IAM policies)."
  type        = string
}

variable "name_prefix" {
  description = "Project prefix for account-global names (IAM policies)."
  type        = string
}

variable "role_name" {
  description = "Name of the GitHub Actions assume-role."
  type        = string
}

variable "repos" {
  description = "GitHub repos allowed to assume the role ('owner/repo')."
  type        = list(string)
}

variable "ref_patterns" {
  description = "GitHub ref patterns allowed to assume the role (wildcarded on the sub claim, e.g. 'ref:refs/heads/main' or 'ref:refs/tags/v*')."
  type        = list(string)
}

variable "manage_provider" {
  description = "Create the account-level GitHub OIDC provider (true for the FIRST environment only; later environments reuse it via a data lookup)."
  type        = bool
}

variable "state_bucket" {
  description = "S3 bucket for the terraform state backend (created here)."
  type        = string
}

variable "state_lock_table" {
  description = "DynamoDB table for terraform state locking (created here)."
  type        = string
}

variable "site_bucket_prefix" {
  description = "Prefix of the S3 site bucket(s) the deploy role may write."
  type        = string
}

variable "tags" {
  type = map(string)
}

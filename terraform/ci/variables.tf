variable "aws_region" {
  description = "Region for the state bucket + lock table (the OIDC provider and role are global). Deployment value — supplied via TF_VAR_aws_region / -var at runtime (bootstrap script, CI secret), never hardcoded."
  type        = string
}

variable "environment" {
  description = "Environment label (staging|prod) — suffixed into account-global names (IAM policies)."
  type        = string
}

variable "name_prefix" {
  description = "Project prefix for account-global names (IAM policies)."
  type        = string
  default     = "my-portfolio"
}

variable "role_name" {
  description = "Name of the GitHub Actions assume-role."
  type        = string
  default     = "github-actions-my-portfolio"
}

variable "repos" {
  description = "GitHub repos allowed to assume the role ('owner/repo')."
  type        = list(string)
  default = [
    "mathewmusango/my-portfolio", # the operational repo
  ]
}

variable "ref_patterns" {
  description = "GitHub ref patterns allowed to assume the role (wildcarded on the sub claim, e.g. 'ref:refs/heads/main' or 'ref:refs/tags/v*')."
  type        = list(string)
  default     = ["*"]
}

variable "manage_provider" {
  description = "Create the account-level GitHub OIDC provider (true for the FIRST environment only; later environments reuse it via a data lookup)."
  type        = bool
  default     = true
}

variable "state_bucket" {
  description = "S3 bucket for the terraform state backend (created here)."
  type        = string
  default     = "my-portfolio-tfstate"
}

variable "state_lock_table" {
  description = "DynamoDB table for terraform state locking (created here)."
  type        = string
  default     = "my-portfolio-tfstate-lock"
}

variable "site_bucket_prefix" {
  description = "Prefix of the future S3 site bucket(s) the deploy role may write."
  type        = string
  default     = "my-portfolio-site"
}

variable "tags" {
  type    = map(string)
  default = { project = "my-portfolio", managed_by = "terraform" }
}

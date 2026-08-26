variable "aws_region" {
  description = "Region for the state bucket + lock table (the OIDC provider and role are global)."
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name of the GitHub Actions assume-role."
  type        = string
  default     = "github-actions-my-portfolio"
}

variable "repos" {
  description = "GitHub repos allowed to assume the role ('owner/repo'). Only mathewmusango/my-portfolio (the operational repo) — the test repo is a mirror and does not run terraform against real AWS."
  type        = list(string)
  default = [
    "mathewmusango/my-portfolio",  # prod repo — runs terraform.yml
  ]
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

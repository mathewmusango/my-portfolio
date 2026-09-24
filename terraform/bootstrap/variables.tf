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
  description = "Name of the GitHub Actions TERRAFORM assume-role (stack plan/apply)."
  type        = string
}

variable "deploy_role_name" {
  description = "Name of the GitHub Actions DEPLOY assume-role (S3 content sync only)."
  type        = string
}

variable "invalidate_role_name" {
  description = "Name of the GitHub Actions EDGE-INVALIDATE assume-role (CloudFront invalidation only)."
  type        = string
}

variable "toggle_role_name" {
  description = "Name of the GitHub Actions EDGE-TOGGLE assume-role (flip Enabled on the project's distributions only)."
  type        = string
}

variable "repos" {
  description = "GitHub repos allowed to assume the role ('owner/repo')."
  type        = list(string)
}

variable "ref_patterns" {
  description = "GitHub ref patterns allowed to assume the TERRAFORM role (wildcarded on the sub claim, e.g. 'ref:refs/heads/main' or 'ref:refs/tags/v*')."
  type        = list(string)
}

variable "deploy_ref_patterns" {
  description = "GitHub ref patterns allowed to assume the DEPLOY role — the deploy workflows fire via workflow_run on the default branch, so this is 'ref:refs/heads/main' (the v*-tag-only intent is enforced by deploy-prod.yml's own branch gate)."
  type        = list(string)
}

variable "manage_provider" {
  description = "Create the account-level GitHub OIDC provider (true for the FIRST environment only; later environments reuse it via a data lookup)."
  type        = bool
}

variable "manage_analyzer" {
  description = "Create the account-level IAM Access Analyzer (true for the env whose state owns it; the other env reuses the account analyzer). Findings: external access + unused access."
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

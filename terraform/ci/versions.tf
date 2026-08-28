terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State: S3 backend, same per-env bucket as the main module but under the
  # 'ci/' key. Values are supplied at init via -backend-config
  # (scripts/bootstrap_aws.sh) — nothing account-specific lives here. The
  # bucket is created by THIS module, so the very first run (greenfield) uses
  # local state and migrates after the bucket exists.
  backend "s3" {}
}

# Standalone root module — apply ONCE to real AWS with admin credentials
# (aws configure / env creds). This is the IAM side of "GitHub Actions → AWS":
#   cd terraform/ci
#   terraform init && terraform apply
# Then copy `outputs.role_arn` into the GitHub repo's variables (AWS_ROLE_ARN).
# NOT for Ministack (no OIDC provider there).

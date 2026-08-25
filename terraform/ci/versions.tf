terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Standalone root module — apply ONCE to real AWS with admin credentials
# (aws configure / env creds). This is the IAM side of "GitHub Actions → AWS":
#   cd terraform/ci
#   terraform init && terraform apply
# Then copy `outputs.role_arn` into the GitHub repo's variables (AWS_ROLE_ARN).
# NOT for Ministack (no OIDC provider there).

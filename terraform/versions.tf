terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # State: shared S3 backend (bucket + lock table created by terraform/ci).
  # Local dev points at the same backend via the AWS env vars (Ministack S3 when
  # AWS_ENDPOINT_URL is set, real S3 otherwise) — every plan/apply shares one state.
  backend "s3" {
    bucket         = "my-portfolio-tfstate"
    key            = "metrics/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-portfolio-tfstate-lock"
    encrypt        = true
  }
}

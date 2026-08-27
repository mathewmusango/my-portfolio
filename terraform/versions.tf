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

  # State: S3 backend — bucket / key / region / lock table are supplied at init
  # via -backend-config (workflow, bootstrap script, or local command) so this
  # module is portable across projects and regions. Nothing account-specific
  # lives in this file.
  backend "s3" {}
}

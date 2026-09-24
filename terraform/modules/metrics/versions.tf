terraform {
  required_version = "~> 1.5"

  # Only terraform/ calls this module and it owns the provider pin, so this
  # declares a floor rather than a ceiling (aws >= 5.0, archive ~> 2.0).
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

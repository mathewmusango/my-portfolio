terraform {
  required_version = "~> 1.5"

  # Same constraints as the root module — the module is only ever called from
  # terraform/, so these must stay compatible (aws ~> 5.0, archive ~> 2.0).
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
}

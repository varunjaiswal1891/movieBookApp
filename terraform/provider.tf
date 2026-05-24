# ─────────────────────────────────────────────────────────────────────────────
# Terraform & AWS Provider
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "moviebook"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

# API Gateway creation can fail for IAM users without tag permissions.
# Use this alias for resources where we need to skip provider-level default tags.
provider "aws" {
  alias  = "no_tags"
  region = var.aws_region
}

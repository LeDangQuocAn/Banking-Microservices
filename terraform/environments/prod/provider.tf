terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
    tls = {
      # Required by modules/eks/main.tf — fetches the live OIDC issuer
      # thumbprint via data.tls_certificate so it is never hardcoded.
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Banking-Microservices"
      Environment = "Prod"
      ManagedBy   = "Terraform"
      Owner       = "KhoiP"
    }
  }
}

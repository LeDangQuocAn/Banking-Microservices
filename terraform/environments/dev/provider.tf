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
    # Required by the EKS module to fetch the OIDC endpoint TLS thumbprint
    # used when creating the IAM OpenID Connect provider for IRSA.
    tls = {
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
      Environment = "Dev"
      ManagedBy   = "Terraform"
      Owner       = "KhoiP"
    }
  }
}
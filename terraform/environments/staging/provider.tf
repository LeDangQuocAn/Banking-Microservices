terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
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
      Environment = "Staging"
      ManagedBy   = "Terraform"
      Owner       = "KhoiP"
    }
  }
}

data "aws_eks_cluster_auth" "staging" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_data)
  token                  = data.aws_eks_cluster_auth.staging.token
}
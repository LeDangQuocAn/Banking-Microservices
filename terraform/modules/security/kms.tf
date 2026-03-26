# ==============================================================
# Security Module — KMS Customer Managed Keys
#
# One CMK per service boundary keeps the blast radius small:
#   eks-secrets  — K8s envelope encryption (secrets at rest)
#   rds          — RDS PostgreSQL storage encryption
#   documentdb   — DocumentDB cluster storage encryption
#   elasticache  — ElastiCache Redis at-rest and in-transit key
#
# Every key has:
#   Automatic annual key rotation enabled
#   Configurable deletion window (7 days Dev / 30 days Prod)
#   Root-account admin statement (enables IAM-based delegation)
#   Service-specific usage statement where AWS requires it
# ==============================================================

# ===== Shared: data sources and locals =====
# These are used by kms.tf, iam.tf, and sg.tf; Terraform merges
# all files in the same module directory into one namespace.
data "aws_caller_identity" "current" {}
locals {
  name_prefix = "${var.project}-${var.env}"
  # KMS alias names must be lowercase; derive from name_prefix.
  alias_prefix = lower(replace(local.name_prefix, " ", "-"))
}

# ==============================================================
# EKS Secrets Key
# Used by the EKS control plane for K8s envelope encryption.
# The EKS cluster IAM role (created in iam.tf) is explicitly
# trusted so it can call GenerateDataKey* and CreateGrant.
# ==============================================================
data "aws_iam_policy_document" "eks_secrets_kms_policy" {
  statement {
    sid    = "EnableRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # The EKS cluster role must be able to wrap/unwrap data keys and
  # create grants so the control plane can delegate to node roles.
  statement {
    sid    = "AllowEKSClusterRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.eks_cluster.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "eks_secrets" {
  description             = "Encrypts Kubernetes secrets at rest in the ${local.name_prefix} EKS cluster."
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.eks_secrets_kms_policy.json

  tags = { Name = "${local.alias_prefix}-eks-secrets-key" }
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${local.alias_prefix}-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets.id
}

# ==============================================================
# RDS Key
# Used for RDS PostgreSQL storage encryption.
# rds.amazonaws.com service principal is required by AWS for
# Multi-AZ and automated snapshot operations.
# ==============================================================
data "aws_iam_policy_document" "rds_kms_policy" {
  statement {
    sid    = "EnableRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowRDSServiceUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
    ]
    resources = ["*"]
  }

  # Secrets Manager uses this key to encrypt the RDS master-credentials
  # secret. The secretsmanager service principal must be explicitly allowed
  # in the key policy — IAM delegation alone is not sufficient.
  statement {
    sid    = "AllowSecretsManagerForRDS"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "rds" {
  description             = "Encrypts RDS PostgreSQL storage in ${local.name_prefix}."
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.rds_kms_policy.json

  tags = { Name = "${local.alias_prefix}-rds-key" }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.alias_prefix}-rds"
  target_key_id = aws_kms_key.rds.id
}

# ==============================================================
# DocumentDB Key
# DocumentDB runs on RDS infrastructure, so it uses the same
# rds.amazonaws.com service principal for key operations.
# ==============================================================
data "aws_iam_policy_document" "documentdb_kms_policy" {
  statement {
    sid    = "EnableRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDocumentDBServiceUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "documentdb" {
  description             = "Encrypts DocumentDB (MongoDB-compatible) cluster storage in ${local.name_prefix}."
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.documentdb_kms_policy.json

  tags = { Name = "${local.alias_prefix}-documentdb-key" }
}

resource "aws_kms_alias" "documentdb" {
  name          = "alias/${local.alias_prefix}-documentdb"
  target_key_id = aws_kms_key.documentdb.id
}

# ==============================================================
# ElastiCache Key
# ElastiCache uses grants (created at CreateReplicationGroup time)
# for at-rest encryption — elasticache.amazonaws.com service
# principal is required so the service can call GenerateDataKey*.
# Secrets Manager also needs access because the Redis AUTH token
# secret is encrypted with this key.
# ==============================================================
data "aws_iam_policy_document" "elasticache_kms_policy" {
  statement {
    sid    = "EnableRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # ElastiCache at-rest encryption: the service uses service-linked role grants;
  # the service principal must be in the key policy to create those grants.
  statement {
    sid    = "AllowElastiCacheServiceUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["elasticache.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]
  }

  # Secrets Manager uses this key to encrypt the Redis AUTH token secret.
  statement {
    sid    = "AllowSecretsManagerForElastiCache"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "elasticache" {
  description             = "Encrypts ElastiCache Redis data at rest in ${local.name_prefix}."
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.elasticache_kms_policy.json

  tags = { Name = "${local.alias_prefix}-elasticache-key" }
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${local.alias_prefix}-elasticache"
  target_key_id = aws_kms_key.elasticache.id
}

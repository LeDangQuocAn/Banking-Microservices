# ==============================================================
# Prod — IRSA Roles for CD Stack
#
# Mirror of staging/irsa.tf with prod-appropriate differences:
#
#   1. GitHub OIDC provider: referenced via DATA SOURCE (not created
#      here — staging workspace owns the resource). Prod just reads it.
#      Dependency order: staging must be applied before prod first time.
#
#   2. Vault KMS key: 30-day deletion window (matching prod security
#      policy). In prod, Vault is NOT destroyed/re-initialised between
#      cycles — the EBS volume containing Vault Raft data and the KMS
#      unseal key must remain stable.
#
#   3. GitHub deploy role: restricted to refs/heads/production only.
#      CI/CD jobs on feature branches cannot assume this role.
#
#   4. External Secrets: scoped to Banking-Microservices-Prod-* secrets.
#
# Resources in this file do NOT use prevent_destroy. The 30-day KMS
# deletion window is the safeguard for Vault unseal continuity.
# ==============================================================

# ===== Locals =====
locals {
  irsa_prefix = "banking-microservices-prod"

  # OIDC issuer without https:// — used in IRSA condition keys.
  oidc_issuer = replace(module.eks.oidc_issuer_url, "https://", "")
}
# ===== End of Locals =====

data "aws_caller_identity" "irsa" {}

# ==============================================================
# GitHub Actions OIDC Provider — DATA SOURCE
# ==============================================================
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
# ===== End of GitHub OIDC Provider =====

# ==============================================================
# KMS Key — Vault Auto-Unseal (Prod)
# ==============================================================
data "aws_iam_policy_document" "vault_kms_key_policy" {
  statement {
    sid    = "EnableRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.irsa.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "vault_unseal" {
  description             = "Vault auto-unseal CMK for ${local.irsa_prefix}. 30-day deletion window — see irsa.tf header before destroying."
  deletion_window_in_days = 30 # Prod: full recovery window.
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_kms_key_policy.json

  tags = { Name = "${local.irsa_prefix}-vault-unseal-key" }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${local.irsa_prefix}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.id
}
# ===== End of Vault KMS Key =====

# ==============================================================
# IRSA — AWS Load Balancer Controller (Prod)
# ==============================================================
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${local.irsa_prefix}-alb-controller-role"
  description        = "IRSA role for the AWS Load Balancer Controller in prod. Manages ALB/NLB lifecycle."
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json

  tags = { Name = "${local.irsa_prefix}-alb-controller-role" }
}

data "aws_iam_policy_document" "alb_controller" {
  statement {
    sid     = "CreateELBServiceLinkedRole"
    effect  = "Allow"
    actions = ["iam:CreateServiceLinkedRole"]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeCoipPools",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeVpcs",
      "ec2:GetCoipPoolUsage",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2SecurityGroupWrite"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteTags",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ELBv2Describe"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTrustStores",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ELBv2Write"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebAcl",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ACMDescribe"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "CognitoDescribe"
    effect    = "Allow"
    actions   = ["cognito-idp:DescribeUserPoolClient"]
    resources = ["*"]
  }

  statement {
    sid    = "WAF"
    effect = "Allow"
    actions = [
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Shield"
    effect = "Allow"
    actions = [
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "TaggingAPI"
    effect = "Allow"
    actions = [
      "tag:GetResources",
      "tag:TagResources",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${local.irsa_prefix}-alb-controller-policy"
  description = "Permissions for the AWS Load Balancer Controller IRSA role in prod (v2.12 policy)."
  policy      = data.aws_iam_policy_document.alb_controller.json

  tags = { Name = "${local.irsa_prefix}-alb-controller-policy" }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
# ===== End of ALB Controller IRSA =====

# ==============================================================
# IRSA — HashiCorp Vault (Prod)
# ==============================================================
data "aws_iam_policy_document" "vault_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:vault:vault"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vault" {
  name               = "${local.irsa_prefix}-vault-role"
  description        = "IRSA role for HashiCorp Vault auto-unseal in prod. Grants KMS Encrypt/Decrypt on the prod vault-unseal CMK only."
  assume_role_policy = data.aws_iam_policy_document.vault_assume_role.json

  tags = { Name = "${local.irsa_prefix}-vault-role" }
}

resource "aws_iam_role_policy" "vault_kms_access" {
  name = "vault-kms-unseal"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "VaultKMSUnseal"
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      Resource = [aws_kms_key.vault_unseal.arn]
    }]
  })
}
# ===== End of Vault IRSA =====

# ==============================================================
# IRSA — External Secrets Operator (Prod)
# ==============================================================
data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${local.irsa_prefix}-external-secrets-role"
  description        = "IRSA role for External Secrets Operator in prod. Read-only access to Banking-Microservices-Prod-* secrets."
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

  tags = { Name = "${local.irsa_prefix}-external-secrets-role" }
}

resource "aws_iam_role_policy" "external_secrets_access" {
  name = "external-secrets-secrets-manager"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadProdSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
        ]
        Resource = [
          # Covers RDS credentials, Redis auth token, DocumentDB credentials.
          # AWS appends a 6-char random suffix — wildcard handles it.
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.irsa.account_id}:secret:Banking-Microservices-Prod-*",
        ]
      },
      {
        Sid      = "ListSecretsForESO"
        Effect   = "Allow"
        Action   = ["secretsmanager:ListSecrets"]
        Resource = ["*"]
      }
    ]
  })
}
# ===== End of External Secrets IRSA =====

# ==============================================================
# IRSA — GitHub Actions Deploy (Prod)
# ==============================================================
data "aws_iam_policy_document" "github_deploy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Production branch only — no wildcards on the branch segment.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:*:ref:refs/heads/production",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${local.irsa_prefix}-github-deploy-role"
  description        = "Assumed by GitHub Actions (production branch only) for kubectl/helm access to the prod EKS cluster."
  assume_role_policy = data.aws_iam_policy_document.github_deploy_assume_role.json

  tags = { Name = "${local.irsa_prefix}-github-deploy-role" }
}

resource "aws_iam_role_policy" "github_deploy_access" {
  name = "eks-describe-prod"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EKSDescribeProd"
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
      ]
      Resource = [
        "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.irsa.account_id}:cluster/${var.cluster_name}",
      ]
    }]
  })
}
# ===== End of GitHub Deploy IRSA =====

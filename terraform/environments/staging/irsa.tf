# ==============================================================
# Staging — IRSA Roles for CD Stack
#
# IRSA (IAM Roles for Service Accounts) lets individual pods assume
# scoped IAM roles via the EKS OIDC provider without node-level creds.
#
# Resources:
#   data.aws_iam_openid_connect_provider.github   — GitHub Actions OIDC
#     (created here; referenced via data source in prod/irsa.tf)
#   aws_kms_key.vault_unseal                      — Vault auto-unseal CMK
#   aws_iam_role.alb_controller + policy          — AWS LB Controller
#   aws_iam_role.vault + inline policy            — HashiCorp Vault
#   aws_iam_role.external_secrets + inline policy — External Secrets Operator
#   aws_iam_role.github_deploy + inline policy    — GitHub Actions kubectl
# ==============================================================

# ===== Locals =====
locals {
  irsa_prefix = "banking-microservices-staging"

  # OIDC issuer URL without the https:// prefix — required for IRSA
  # condition keys (e.g. "oidc.eks.ap-southeast-1.amazonaws.com/id/XXXX:sub").
  oidc_issuer = replace(module.eks.oidc_issuer_url, "https://", "")
}
# ===== End of Locals =====

# Provides the current AWS account ID
data "aws_caller_identity" "irsa" {}

# ==============================================================
# GitHub Actions OIDC Provider
# ==============================================================
# This provider is account-global and is expected to already exist
# (created by the ECR push role setup). Using a data source means
# destroy/re-apply cycles do not delete it and break other pipelines.
# If it truly does not exist yet, create it once manually:
#   aws iam create-open-id-connect-provider \
#     --url https://token.actions.githubusercontent.com \
#     --client-id-list sts.amazonaws.com \
#     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
# ===== End of GitHub OIDC Provider =====

# ==============================================================
# KMS Key — Vault Auto-Unseal
# ==============================================================
data "aws_iam_policy_document" "vault_kms_key_policy" {
  # Root admin — AWS requires this statement so IAM policies can
  # further delegate KMS access. Without it, only the key policy applies.
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
  description             = "Vault auto-unseal CMK for ${local.irsa_prefix}. Recreated each apply cycle — see irsa.tf header."
  deletion_window_in_days = 7
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
# IRSA — AWS Load Balancer Controller
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
  description        = "IRSA role for the AWS Load Balancer Controller. Manages ALB/NLB lifecycle via Ingress and Service objects."
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json

  tags = { Name = "${local.irsa_prefix}-alb-controller-role" }
}

data "aws_iam_policy_document" "alb_controller" {
  # ELB service-linked role — needed only on first use per account.
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

  # EC2 read-only — no resource scoping possible on Describe operations.
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

  # EC2 write — manages security groups for ALB-to-node traffic rules.
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

  # ELBv2 read-only operations.
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

  # ELBv2 write — full CRUD on load balancers, target groups, listeners, rules.
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

  # ACM — for HTTPS listeners and certificate discovery on ALBs.
  statement {
    sid    = "ACMDescribe"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
    ]
    resources = ["*"]
  }

  # Cognito — for Cognito-integrated ALB authentication listeners.
  statement {
    sid       = "CognitoDescribe"
    effect    = "Allow"
    actions   = ["cognito-idp:DescribeUserPoolClient"]
    resources = ["*"]
  }

  # WAF/WAFv2 — for WAF ACL association on ALB listeners.
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

  # Shield — for ALB DDoS protection registration.
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

  # Resource Groups Tagging API — controller uses tags to discover
  # and reconcile ALB resources it owns.
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
  description = "Permissions for the AWS Load Balancer Controller IRSA role (v2.12 policy)."
  policy      = data.aws_iam_policy_document.alb_controller.json

  tags = { Name = "${local.irsa_prefix}-alb-controller-policy" }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
# ===== End of ALB Controller IRSA =====

# ==============================================================
# IRSA — HashiCorp Vault (KMS Auto-Unseal)
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
  description        = "IRSA role for HashiCorp Vault auto-unseal. Grants KMS Encrypt/Decrypt only on the vault-unseal CMK."
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
      # Scoped exclusively to the vault-unseal key — no wildcard.
      Resource = [aws_kms_key.vault_unseal.arn]
    }]
  })
}
# ===== End of Vault IRSA =====

# ==============================================================
# IRSA — External Secrets Operator (ESO)
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
  description        = "IRSA role for External Secrets Operator. Read-only access to Banking-Microservices-Staging-* secrets."
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
        Sid    = "ReadStagingSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
        ]
        # Scoped to secrets created by this workspace.
        # AWS appends a 6-char random suffix to secret names; the wildcard handles it.
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.irsa.account_id}:secret:Banking-Microservices-Staging-*",
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
# IRSA — GitHub Actions Deploy (kubectl / helm access)
# ==============================================================
data "aws_iam_policy_document" "github_deploy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Restrict to workflows running from the main or master branch
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:LeDangQuocAn/Banking-Microservices:ref:refs/heads/main",
        "repo:LeDangQuocAn/Banking-Microservices:ref:refs/heads/master",
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
  description        = "Assumed by GitHub Actions (main/master branch) for kubectl/helm access to the staging EKS cluster."
  assume_role_policy = data.aws_iam_policy_document.github_deploy_assume_role.json

  tags = { Name = "${local.irsa_prefix}-github-deploy-role" }
}

resource "aws_iam_role_policy" "github_deploy_access" {
  name = "eks-describe-staging"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EKSDescribeStaging"
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
      ]
      # Scoped to this specific cluster only.
      Resource = [
        "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.irsa.account_id}:cluster/${var.cluster_name}",
      ]
    }]
  })
}
# ===== End of GitHub Deploy IRSA =====

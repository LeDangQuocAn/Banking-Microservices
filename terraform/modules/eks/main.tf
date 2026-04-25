# ==============================================================
# EKS Module — Cluster and OIDC Provider
# ==============================================================

# ===== Locals =====
locals {
  name_prefix = "${var.project}-${var.env}"
}
# ===== End of Locals =====

# ==============================================================
# EKS Cluster
#
# Design decisions:
#   • Both private and public API endpoint access are enabled.
#     Private: nodes talk to the control plane over the VPC backbone.
#     Public:  engineers can run kubectl from outside the VPC.
#     Restrict public_access_cidrs to known IPs in Prod.
#
#   • All five control-plane log types are sent to CloudWatch
#     to satisfy audit trail requirements for a finance workload.
#     (api, audit, authenticator, controllerManager, scheduler)
#
#   • Envelope encryption of K8s Secrets uses the CMK provisioned
#     in the security module. Without this, Secrets land in etcd
#     encrypted only by the AESCBC key that EKS manages — which is
#     not auditable. With KMS encryption you get one CloudTrail
#     event per Secret wrap/unwrap operation.
# ==============================================================
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.eks_cluster_role_arn

  # API_AND_CONFIG_MAP enables both the EKS Access API (aws_eks_access_entry)
  # and the legacy aws-auth ConfigMap simultaneously. This is a one-way
  # in-place upgrade from CONFIG_MAP — no cluster replacement required.
  # Required for aws_eks_access_entry resources in irsa.tf to work.
  #
  # bootstrap_cluster_creator_admin_permissions must be carried forward
  # explicitly — omitting it causes Terraform to diff null vs true and
  # force a cluster replacement.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    # Pass both public and private subnet IDs so the control plane
    # can place ENIs in any AZ for cross-zone communication.
    subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  # Envelope-encrypt every K8s Secret using the CMK from the security module.
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.eks_secrets_kms_key_arn
    }
  }

  # Control-plane logs shipped to CloudWatch Logs.
  # Log group /aws/eks/<cluster_name>/cluster is auto-created by EKS.
  enabled_cluster_log_types = [
    "api",               # Kubernetes API server requests
    "audit",             # K8s audit log (who did what, when)
    "authenticator",     # IAM authenticator (aws-auth mapping)
    "controllerManager", # Deployment, ReplicaSet, Job controllers
    "scheduler",         # Pod scheduling decisions
  ]

  tags = { Name = var.cluster_name }
}

# ==============================================================
# OIDC Identity Provider
#
# Enables IAM Roles for Service Accounts (IRSA) — the mechanism
# that gives individual pods a least-privilege IAM role instead
# of inheriting broad node-level permissions.
#
# Workflow:
#   1. Each pod's service account is annotated with an IAM role ARN.
#   2. The EKS pod identity webhook injects AWS_WEB_IDENTITY_TOKEN_FILE
#      into the pod at runtime.
#   3. The AWS SDK exchanges that token via sts:AssumeRoleWithWebIdentity
#      against this OIDC provider, receiving scoped credentials.
#
# The TLS thumbprint is fetched from the OIDC endpoint at plan time
# so it stays fresh if AWS rotates the certificate.
# ==============================================================
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = { Name = "${local.name_prefix}-eks-oidc" }
}

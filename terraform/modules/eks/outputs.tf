# ==============================================================
# EKS Module — Outputs
#
# Consumed by downstream modules and the environment root:
#   ArgoCD, Helm provider, kubectl  → cluster_endpoint, cluster_ca_data, cluster_name
#   Future IRSA roles               → oidc_provider_arn, oidc_issuer_url
#   Monitoring / GitOps tooling     → node_group_name
# ==============================================================

# ===== Cluster =====
output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "URL of the Kubernetes API server. Used by kubectl, the Helm provider, and the ArgoCD app-of-apps bootstrap."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_data" {
  description = "Base64-encoded certificate authority data for the cluster. Required by kubectl and the Kubernetes Terraform provider."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version currently running in the cluster."
  value       = aws_eks_cluster.main.version
}
# ===== End of Cluster =====

# ===== OIDC / IRSA =====
output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider. Used when creating IRSA trust-policy documents for pod-level IAM roles in later."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_issuer_url" {
  description = "HTTPS URL of the OIDC issuer (without trailing slash). Used as the variable portion of IRSA condition keys."
  value       = aws_iam_openid_connect_provider.eks.url
}
# ===== End of OIDC / IRSA =====

# ===== Node Group =====
output "node_group_name" {
  description = "Name of the EKS managed node group."
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_arn" {
  description = "ARN of the EKS managed node group."
  value       = aws_eks_node_group.main.arn
}
# ===== End of Node Group =====
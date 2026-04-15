# === VPC outputs ===
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the Prod VPC."
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of public subnets (ALB, NAT Gateway)."
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "IDs of private subnets (EKS nodes, RDS, caches)."
}

output "nat_public_ips" {
  value       = module.vpc.nat_public_ips
  description = "Elastic IPs of NAT Gateways — add to external service allowlists."
}
# === End of VPC outputs ===

# === Security outputs ===
output "eks_cluster_role_arn" {
  value       = module.security.eks_cluster_role_arn
  description = "IAM role ARN assumed by the EKS control plane."
}

output "eks_node_group_role_arn" {
  value       = module.security.eks_node_group_role_arn
  description = "IAM role ARN assumed by EKS worker nodes."
}

output "alb_sg_id" {
  value       = module.security.alb_sg_id
  description = "Security group ID of the Application Load Balancer."
}

output "eks_node_sg_id" {
  value       = module.security.eks_node_sg_id
  description = "Security group ID of EKS worker nodes."
}
# === End of Security outputs ===

# === EKS outputs ===
output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the Prod EKS cluster."
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Kubernetes API server endpoint — use with kubectl and the Helm provider."
}

output "eks_cluster_ca_data" {
  value       = module.eks.cluster_ca_data
  description = "Base64-encoded cluster CA certificate."
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN — used when creating IRSA trust policies."
}
# === End of EKS outputs ===

# === RDS outputs ===
output "rds_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS PostgreSQL connection endpoint (host:port)."
}

output "rds_secret_arn" {
  value       = module.rds.db_secret_arn
  description = "Secrets Manager ARN for RDS master credentials — grant GetSecretValue to application pods."
}
# === End of RDS outputs ===

# === DocumentDB outputs ===
output "docdb_endpoint" {
  value       = module.documentdb.cluster_endpoint
  description = "DocumentDB writer endpoint — used by log-service MongoDB driver."
}

output "docdb_secret_arn" {
  value       = module.documentdb.secret_arn
  description = "Secrets Manager ARN for DocumentDB master credentials."
}
# === End of DocumentDB outputs ===

# === ElastiCache outputs ===
output "redis_primary_endpoint" {
  value       = module.elasticache.primary_endpoint
  description = "ElastiCache Redis primary endpoint address."
}

output "redis_secret_arn" {
  value       = module.elasticache.secret_arn
  description = "Secrets Manager ARN for the Redis AUTH token."
}
# === End of ElastiCache outputs ===

# === ECR outputs ===
output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "Map of service name → ECR repository URL. Use as the 'image:' field in Kubernetes Deployment manifests."
}

output "ecr_registry_id" {
  value       = module.ecr.registry_id
  description = "AWS account ID owning the ECR registry — required for 'aws ecr get-login-password'."
}
# === End of ECR outputs ===

# ===== IRSA outputs =====
output "irsa_alb_controller_role_arn" {
  value       = aws_iam_role.alb_controller.arn
  description = "IRSA role ARN for the AWS Load Balancer Controller in prod."
}

output "irsa_vault_role_arn" {
  value       = aws_iam_role.vault.arn
  description = "IRSA role ARN for HashiCorp Vault auto-unseal in prod."
}

output "irsa_vault_kms_key_arn" {
  value       = aws_kms_key.vault_unseal.arn
  description = "KMS CMK ARN for Vault auto-unseal in prod. Pass as awsKmsKeyId in the Vault Helm values."
}

output "irsa_external_secrets_role_arn" {
  value       = aws_iam_role.external_secrets.arn
  description = "IRSA role ARN for External Secrets Operator in prod."
}

output "irsa_github_deploy_role_arn" {
  value       = aws_iam_role.github_deploy.arn
  description = "IRSA role ARN assumed by GitHub Actions production-branch jobs for kubectl/helm access."
}
# ===== End of IRSA outputs =====

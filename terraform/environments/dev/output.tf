# === Output variables for the S3 bucket ===
output "s3_bucket_id" {
  value       = aws_s3_bucket.terraform_state.id
  description = "ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket"
}

output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Name of the Dev Terraform remote state S3 bucket. Dev owns this bucket exclusively — destroying Dev removes this bucket only."
}
# === End of output variables for the S3 bucket ===

# === VPC outputs ===
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the Dev VPC."
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
  description = "Name of the Dev EKS cluster."
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
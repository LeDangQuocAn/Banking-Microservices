# ==============================================================
# Security Module — Outputs
#
# Consumed by downstream modules:
#   eks         → eks_cluster_role_arn, eks_node_group_role_arn,
#                 eks_secrets_kms_key_arn, eks_node_sg_id
#   rds         → rds_kms_key_arn, rds_sg_id
#   documentdb  → documentdb_kms_key_arn, documentdb_sg_id
#   elasticache → elasticache_kms_key_arn, elasticache_sg_id
# ==============================================================

# ===== KMS Key ARNs =====
output "eks_secrets_kms_key_arn" {
  description = "ARN of the CMK used for EKS K8s secrets envelope encryption."
  value       = aws_kms_key.eks_secrets.arn
}

output "rds_kms_key_arn" {
  description = "ARN of the CMK used for RDS PostgreSQL storage encryption."
  value       = aws_kms_key.rds.arn
}

output "documentdb_kms_key_arn" {
  description = "ARN of the CMK used for DocumentDB cluster storage encryption."
  value       = aws_kms_key.documentdb.arn
}

output "elasticache_kms_key_arn" {
  description = "ARN of the CMK used for ElastiCache Redis at-rest encryption."
  value       = aws_kms_key.elasticache.arn
}
# ===== End of KMS Key ARNs =====

# ===== IAM Role ARNs =====
output "eks_cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the IAM role assumed by EKS worker nodes."
  value       = aws_iam_role.eks_node_group.arn
}
# ===== End of IAM Role ARNs =====

# ===== Security Group IDs =====
output "alb_sg_id" {
  description = "ID of the Application Load Balancer security group (internet-facing)."
  value       = aws_security_group.alb.id
}

output "eks_node_sg_id" {
  description = "ID of the additional EKS worker-node security group."
  value       = aws_security_group.eks_node.id
}

output "rds_sg_id" {
  description = "ID of the RDS PostgreSQL security group."
  value       = aws_security_group.rds.id
}

output "elasticache_sg_id" {
  description = "ID of the ElastiCache Redis security group."
  value       = aws_security_group.elasticache.id
}

output "documentdb_sg_id" {
  description = "ID of the DocumentDB security group."
  value       = aws_security_group.documentdb.id
}
# ===== End of Security Group IDs =====
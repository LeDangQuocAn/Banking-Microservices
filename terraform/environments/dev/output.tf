# === Output variables for the S3 bucket ===
output "s3_bucket_id" {
  value       = aws_s3_bucket.terraform_state.id
  description = "ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket"
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
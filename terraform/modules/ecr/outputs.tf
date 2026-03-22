# ==============================================================
# ECR Module — Outputs
#
# Consumed by:
#   CI/CD pipeline             → repository_urls (push images)
#   EKS Deployments / Helm     → repository_url_map (image: field)
#   Monitoring / audit tooling → repository_arns
# ==============================================================

output "repository_urls" {
  description = "Map of service name → ECR repository URL (without tag). Use as the image field in Kubernetes Deployment manifests: '<url>:<tag>'."
  value       = { for name, repo in aws_ecr_repository.main : name => repo.repository_url }
}

output "repository_arns" {
  description = "Map of service name → ECR repository ARN. Use when granting IAM permissions scoped to specific repositories."
  value       = { for name, repo in aws_ecr_repository.main : name => repo.arn }
}

output "registry_id" {
  description = "AWS account ID that owns the ECR registry. Required by 'aws ecr get-login-password' and docker login commands. Sourced from aws_caller_identity rather than extracted from the repository resource."
  value       = data.aws_caller_identity.current.account_id
}

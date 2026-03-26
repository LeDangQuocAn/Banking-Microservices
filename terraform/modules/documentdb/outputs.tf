# ==============================================================
# DocumentDB Module — Outputs
#
# Consumed by:
#   log-service (via Secrets Manager) → cluster_endpoint, cluster_port
#   CloudWatch alarms, console        → cluster_id
# ==============================================================

output "cluster_endpoint" {
  description = "Writer endpoint of the DocumentDB cluster. All write operations must target this endpoint."
  value       = aws_docdb_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for load-balanced read-only connections. Unused with a single instance but available when instance_count >= 2 in Prod."
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "Port the DocumentDB cluster listens on (default 27017)."
  value       = aws_docdb_cluster.main.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding master credentials. Application pods must have an IAM policy granting secretsmanager:GetSecretValue on this ARN."
  value       = aws_secretsmanager_secret.docdb.arn
}

output "cluster_id" {
  description = "DocumentDB cluster identifier. Used for CloudWatch alarms and the DocumentDB console."
  value       = aws_docdb_cluster.main.cluster_identifier
}

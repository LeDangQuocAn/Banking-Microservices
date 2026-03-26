# ==============================================================
# RDS Module — Outputs
#
# Consumed by:
#   Application pods (via Secrets Manager, not direct injection)
#   CloudWatch alarms, RDS console deep-links → db_instance_id
#   Other modules or monitoring → db_endpoint
# ==============================================================

output "db_endpoint" {
  description = "Connection endpoint (host:port) for the RDS PostgreSQL instance. Use as the datasource URL in Spring Boot applications."
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "Hostname of the RDS PostgreSQL instance without the port suffix."
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port the RDS PostgreSQL instance listens on (5432)."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.main.db_name
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials JSON. Application pods must have an IAM policy granting secretsmanager:GetSecretValue on this ARN."
  value       = aws_secretsmanager_secret.rds.arn
}

output "db_instance_id" {
  description = "Identifier of the RDS instance. Used when creating CloudWatch alarms and Enhanced Monitoring dashboards."
  value       = aws_db_instance.main.id
}

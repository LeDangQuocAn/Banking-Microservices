# ==============================================================
# ElastiCache Module — Outputs
#
# Consumed by:
#   Application pods (via Secrets Manager) → primary_endpoint, port
#   CloudWatch alarms, console             → replication_group_id
# ==============================================================

output "primary_endpoint" {
  description = "Primary endpoint address for Redis write and read operations in a single-node cluster."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint for load-balanced read-only connections. Available when num_cache_nodes >= 2."
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "Port Redis listens on (default 6379)."
  value       = aws_elasticache_replication_group.main.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Redis AUTH token. Application pods must have an IAM policy granting secretsmanager:GetSecretValue on this ARN."
  value       = aws_secretsmanager_secret.redis.arn
}

output "replication_group_id" {
  description = "ElastiCache replication group identifier. Used for CloudWatch alarms and the ElastiCache console."
  value       = aws_elasticache_replication_group.main.replication_group_id
}

# ==============================================================
# Amazon MQ Module — Outputs
# ==============================================================

output "broker_id" {
  description = "Amazon MQ broker ID."
  value       = aws_mq_broker.main.id
}

output "broker_arn" {
  description = "Amazon MQ broker ARN."
  value       = aws_mq_broker.main.arn
}

output "security_group_id" {
  description = "Security group ID attached to the Amazon MQ broker."
  value       = aws_security_group.main.id
}

output "endpoints" {
  description = "AMQPS endpoint URLs exposed by the Amazon MQ broker."
  value       = local.mq_endpoints
}

output "endpoint_url" {
  description = "Primary AMQPS endpoint URL for application configuration."
  value       = local.mq_endpoints[0]
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing RabbitMQ credentials and AMQPS endpoint metadata."
  value       = aws_secretsmanager_secret.mq.arn
}

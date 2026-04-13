# ==============================================================
# ElastiCache Module — Redis Replication Group
#
# Resource breakdown (6 resources):
#   aws_elasticache_subnet_group       — private subnets
#   aws_elasticache_parameter_group    — redis<major> family
#   random_password                    — auto-generates AUTH token
#   aws_secretsmanager_secret          — secret envelope (encrypted with CMK)
#   aws_secretsmanager_secret_version  — AUTH token JSON
#   aws_elasticache_replication_group  — Redis cluster
#
# Design decisions:
#   • at_rest_encryption_enabled  = true  — storage encrypted with CMK
#   • transit_encryption_enabled  = true  — TLS for all client connections
#   • auth_token                          — required when TLS is enabled;
#     token is generated here and stored in Secrets Manager 
#     since Secrets Manager tightly integrates with ElastiCache.
#   • AUTH token is marked sensitive by Terraform; state encrypted via S3 CMK
#   • lifecycle ignore_changes on auth_token prevents Terraform from resetting
#     a rotated token on the next apply
#
# Dev / Prod sizing:
#   Dev:  num_cache_nodes=1, automatic_failover_enabled=false
#   Prod: num_cache_nodes=2, automatic_failover_enabled=true
#         (multi_az_enabled is tied to automatic_failover_enabled)
# ==============================================================

# ===== Locals =====
locals {
  name_prefix  = "${var.project}-${var.env}"
  # Extract major version for parameter group family: "7.1" → "redis7"
  redis_family = "redis${split(".", var.engine_version)[0]}"
}
# ===== End of Locals =====

# ===== Subnet Group =====
resource "aws_elasticache_subnet_group" "main" {
  name        = lower("${local.name_prefix}-redis-subnet-group")
  subnet_ids  = var.private_subnet_ids
  description = "Private subnets for ${local.name_prefix} ElastiCache Redis cluster."

  tags = { Name = "${local.name_prefix}-redis-subnet-group" }
}
# ===== End of Subnet Group =====

# ===== Parameter Group =====
resource "aws_elasticache_parameter_group" "main" {
  name        = lower("${local.name_prefix}-redis-pg")
  family      = local.redis_family # e.g. "redis7"
  description = "Redis ${split(".", var.engine_version)[0]} parameter group for ${local.name_prefix}."

  tags = { Name = "${local.name_prefix}-redis-pg" }
}
# ===== End of Parameter Group =====

# ===== AUTH Token — Secrets Manager =====
# ElastiCache Redis requires the AUTH token when transit_encryption_enabled = true.
resource "random_password" "redis_auth" {
  length  = 32
  special = true
  # Stick to the minimal safe set to guarantee no API rejection.
  override_special = "!&#_-"
}

resource "aws_secretsmanager_secret" "redis" {
  name        = "${local.name_prefix}-redis-auth-token"
  description = "Redis AUTH token for ${local.name_prefix} ElastiCache cluster."
  kms_key_id  = var.kms_key_arn

  # 0   = immediate deletion on destroy (Dev — fast rebuild cycles).
  # 7   = 7-day recovery window (Prod — allows recovery from accidental destroy).
  # Set via secret_recovery_window_days in tfvars per environment.
  recovery_window_in_days = var.secret_recovery_window_days

  tags = { Name = "${local.name_prefix}-redis-auth-token" }
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id

  secret_string = jsonencode({
    auth_token = random_password.redis_auth.result
    host       = aws_elasticache_replication_group.main.primary_endpoint_address
    port       = var.port
  })
}
# ===== End of AUTH Token =====

# ===== ElastiCache Redis Replication Group =====
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = lower("${local.name_prefix}-redis")
  description          = "Redis cache cluster for ${local.name_prefix} banking microservices."

  # Engine
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  port                 = var.port
  parameter_group_name = aws_elasticache_parameter_group.main.name

  # Networking
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.sg_id]

  # Encryption at rest and in transit
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result

  # Availability
  # multi_az_enabled must match automatic_failover_enabled; both require >= 2 nodes.
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.automatic_failover_enabled

  # Snapshots
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "02:00-03:00"
  maintenance_window       = "mon:03:00-mon:04:00"

  # Prevent Terraform from resetting a rotated AUTH token on the next apply.
  lifecycle {
    ignore_changes = [auth_token]
  }

  tags = { Name = "${local.name_prefix}-redis" }
}
# ===== End of ElastiCache Redis Replication Group =====

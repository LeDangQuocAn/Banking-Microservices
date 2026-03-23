# ==============================================================
# RDS Module — PostgreSQL
#
# Resource breakdown (6 resources):
#   aws_db_subnet_group             — spans all private subnets
#   aws_db_parameter_group          — pg<major> family, named so we can
#                                     change parameters without replacing
#                                     the instance
#   random_password                 — auto-generates a 32-char master password
#   aws_secretsmanager_secret       — secret envelope (encrypted with CMK)
#   aws_secretsmanager_secret_version — actual credential JSON
#   aws_db_instance                 — PostgreSQL instance
#
# Design decisions:
#   • Password is generated here; NEVER supplied as a tfvars value.
#     Stored in Secrets Manager since Secrets Manager tightly integrates with RDS.
#   • No public endpoint — accessible only from EKS nodes via rds_sg_id.
#   • Storage encrypted with the dedicated CMK from the security module.
#   • Storage autoscaling enabled (max 100 GiB) to avoid capacity issues.
#   • lifecycle ignore_changes on password prevents Terraform from resetting
#     an externally rotated password on the next apply.
# ==============================================================

# ===== Locals =====
locals {
  name_prefix    = "${var.project}-${var.env}"
  # Extract major version for parameter group family: "15.7" → "postgres15"
  pg_major       = split(".", var.engine_version)[0]
}
# ===== End of Locals =====

# ===== Subnet Group =====
# RDS requires a subnet group spanning at least 2 AZs for Multi-AZ and
# for the subnet-group API constraint even in single-AZ mode.
resource "aws_db_subnet_group" "main" {
  name        = lower("${local.name_prefix}-rds-subnet-group")
  subnet_ids  = var.private_subnet_ids
  description = "Private subnets for ${local.name_prefix} RDS PostgreSQL instance."

  tags = { Name = "${local.name_prefix}-rds-subnet-group" }
}
# ===== End of Subnet Group =====

# ===== Parameter Group =====
# Using a named parameter group (instead of the AWS default) means parameter
# changes can be applied in-place without requiring an instance replacement.
resource "aws_db_parameter_group" "main" {
  name        = lower("${local.name_prefix}-rds-postgres${local.pg_major}")
  family      = "postgres${local.pg_major}" # e.g. "postgres15"
  description = "PostgreSQL ${local.pg_major} parameter group for ${local.name_prefix}."

  tags = { Name = "${local.name_prefix}-rds-postgres${local.pg_major}" }
}
# ===== End of Parameter Group =====

# ===== Master Password — Secrets Manager =====
# Password is generated once and locked in state. The `lifecycle` block on
# the DB instance ignores future changes to the password attribute so that
# an externally rotated secret doesn't trigger an instance modification on
# the next `terraform apply`.
resource "random_password" "rds_master" {
  length  = 32
  special = true
  # RDS forbids /, @, ", and whitespace in master passwords.
  override_special = "!#$%^&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "rds" {
  name        = "${local.name_prefix}-rds-credentials"
  description = "Master credentials for ${local.name_prefix} RDS PostgreSQL instance."
  kms_key_id  = var.kms_key_arn

  # 0   = immediate deletion on destroy (Dev — fast rebuild cycles).
  # 7   = 7-day recovery window (Prod — allows recovery from accidental destroy).
  # Set via secret_recovery_window_days in tfvars per environment.
  recovery_window_in_days = var.secret_recovery_window_days

  tags = { Name = "${local.name_prefix}-rds-credentials" }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  # JSON format understood by the aws-java-sdk SecretsManagerBuilder.
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds_master.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}
# ===== End of Master Password =====

# ===== RDS PostgreSQL Instance =====
resource "aws_db_instance" "main" {
  identifier = lower("${local.name_prefix}-postgres")

  # Engine
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = 100      # autoscaling ceiling; set higher for Prod
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.rds_master.result

  # Parameter group — uses the named group rather than the AWS default
  parameter_group_name = aws_db_parameter_group.main.name

  # Networking — private subnets only; no public internet access
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.sg_id]
  publicly_accessible    = false

  # Availability
  multi_az = var.multi_az

  # Backups
  backup_retention_period   = var.backup_retention_days
  backup_window             = "02:00-03:00"  # UTC — quiet period for ap-southeast-1
  maintenance_window        = "Mon:03:00-Mon:04:00"

  # Protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : lower("${local.name_prefix}-postgres-final-snap")

  # Prevent Terraform from resetting an externally rotated password.
  lifecycle {
    ignore_changes = [password]
  }

  tags = { Name = "${local.name_prefix}-postgres" }
}
# ===== End of RDS PostgreSQL Instance =====

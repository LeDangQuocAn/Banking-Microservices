# ==============================================================
# DocumentDB Module — MongoDB-Compatible Cluster
#
# Used by: log-service (MongoDB wire protocol, port 27017)
#
# Resource breakdown (7 resources):
#   aws_docdb_subnet_group            — private subnets
#   aws_docdb_cluster_parameter_group — TLS enforcement
#   random_password                   — auto-generates master password
#   aws_secretsmanager_secret         — secret envelope (encrypted with CMK)
#   aws_secretsmanager_secret_version — credential JSON
#   aws_docdb_cluster                 — cluster control plane
#   aws_docdb_cluster_instance        — one instance per count.index
#
# Design decisions:
#   • TLS is enforced at the parameter group level (tls = enabled).
#     All MongoDB clients must connect with TLS — the DocumentDB
#     CA bundle is available at:
#     https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
#   • Password never appears in plan output (random_password.result is
#     marked sensitive); stored securely in Secrets Manager 
#     since Secrets Manager tightly integrates with DocumentDB.
#   • lifecycle ignore_changes on master_password prevents Terraform
#     from resetting an externally rotated password.
# ==============================================================

# ===== Locals =====
locals {
  name_prefix = "${var.project}-${var.env}"
  # Parameter group family uses major.minor only — "5.0.0" → "docdb5.0"
  # AWS rejects the patch segment (e.g. "docdb5.0.0" is invalid).
  docdb_family = "docdb${join(".", slice(split(".", var.engine_version), 0, 2))}"
}
# ===== End of Locals =====

# ===== Subnet Group =====
resource "aws_docdb_subnet_group" "main" {
  name        = lower("${local.name_prefix}-docdb-subnet-group")
  subnet_ids  = var.private_subnet_ids
  description = "Private subnets for ${local.name_prefix} DocumentDB cluster."

  tags = { Name = "${local.name_prefix}-docdb-subnet-group" }
}
# ===== End of Subnet Group =====

# ===== Cluster Parameter Group =====
# tls = enabled forces all connections to use TLS regardless of client config.
# This is a hard requirement for a finance application.
resource "aws_docdb_cluster_parameter_group" "main" {
  name        = lower("${local.name_prefix}-docdb-pg")
  family      = local.docdb_family # e.g. "docdb5.0"
  description = "TLS-enforcing parameter group for ${local.name_prefix} DocumentDB."

  parameter {
    name  = "tls"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-docdb-pg" }
}
# ===== End of Cluster Parameter Group =====

# ===== Master Password — Secrets Manager =====
resource "random_password" "docdb_master" {
  length  = 32
  special = true
  # DocumentDB forbids /, @, ", and whitespace in master passwords.
  override_special = "!#$%^&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "docdb" {
  name        = "${local.name_prefix}-docdb-credentials"
  description = "Master credentials for ${local.name_prefix} DocumentDB cluster."
  kms_key_id  = var.kms_key_arn

  # 0   = immediate deletion on destroy (Dev — fast rebuild cycles).
  # 7   = 7-day recovery window (Prod — allows recovery from accidental destroy).
  # Set via secret_recovery_window_days in tfvars per environment.
  recovery_window_in_days = var.secret_recovery_window_days

  tags = { Name = "${local.name_prefix}-docdb-credentials" }
}

resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id = aws_secretsmanager_secret.docdb.id

  # Connection string fields used by the Spring Data MongoDB driver.
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.docdb_master.result
    engine   = "mongo"
    host     = aws_docdb_cluster.main.endpoint
    port     = aws_docdb_cluster.main.port
    dbname   = "logs"
  })
}
# ===== End of Master Password =====

# ===== DocumentDB Cluster =====
resource "aws_docdb_cluster" "main" {
  cluster_identifier = lower("${local.name_prefix}-docdb")
  engine             = "docdb"
  engine_version     = var.engine_version

  master_username = var.master_username
  master_password = random_password.docdb_master.result

  # Networking
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  vpc_security_group_ids          = [var.sg_id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name

  # Encryption at rest
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Backups
  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "mon:03:00-mon:04:00"

  # Protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : lower("${local.name_prefix}-docdb-final-snap")

  # Prevent Terraform from resetting an externally rotated password.
  lifecycle {
    ignore_changes = [master_password]
  }

  tags = { Name = "${local.name_prefix}-docdb" }
}
# ===== End of DocumentDB Cluster =====

# ===== DocumentDB Instance(s) =====
# Dev: 1 instance (primary only)
# Prod: 2+ instances (primary + reader replica for failover)
resource "aws_docdb_cluster_instance" "main" {
  count = var.instance_count

  identifier         = lower("${local.name_prefix}-docdb-${count.index + 1}")
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class

  tags = { Name = "${local.name_prefix}-docdb-${count.index + 1}" }
}
# ===== End of DocumentDB Instance(s) =====

# ==============================================================
# Amazon MQ Module — RabbitMQ
#
# Academic production simulation:
#   - ACTIVE_STANDBY_MULTI_AZ for HA semantics.
#   - mq.m7g.medium by default to keep costs bounded.
#   - No prevent_destroy/deletion protection so terraform destroy is clean.
# ==============================================================

locals {
  name_prefix = "${var.project}-${var.env}"
  mq_endpoints = flatten([
    for instance in aws_mq_broker.main.instances : instance.endpoints
  ])
}

resource "random_password" "mq_user" {
  length  = 8
  special = false
}

resource "random_password" "mq_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>?"
}

resource "aws_security_group" "main" {
  name        = lower("${local.name_prefix}-amazon-mq-sg")
  description = "Amazon MQ RabbitMQ: allows AMQPS 5671 inbound from EKS worker nodes only."
  vpc_id      = var.vpc_id

  lifecycle { create_before_destroy = true }

  tags = { Name = "${local.name_prefix}-amazon-mq-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "amqps_from_eks" {
  security_group_id            = aws_security_group.main.id
  description                  = "AMQPS from EKS worker nodes."
  referenced_security_group_id = var.eks_node_sg_id
  from_port                    = 5671
  to_port                      = 5671
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.main.id
  description       = "All outbound for Amazon MQ broker maintenance traffic."
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_mq_broker" "main" {
  broker_name = lower("${local.name_prefix}-rabbitmq")

  engine_type        = "RabbitMQ"
  engine_version     = var.engine_version
  host_instance_type = var.host_instance_type
  deployment_mode    = "SINGLE_INSTANCE"

  subnet_ids          = [var.private_subnet_ids[0]]
  security_groups     = [aws_security_group.main.id]
  publicly_accessible = false
  apply_immediately   = true

  auto_minor_version_upgrade = true

  user {
    username = random_password.mq_user.result
    password = random_password.mq_password.result
  }

  logs {
    general = true
  }

  tags = { Name = "${local.name_prefix}-rabbitmq" }
}

resource "aws_secretsmanager_secret" "mq" {
  name        = "${local.name_prefix}-amazon-mq-credentials"
  description = "RabbitMQ credentials and AMQPS endpoints for ${local.name_prefix} Amazon MQ broker."
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = var.secret_recovery_window_days

  tags = { Name = "${local.name_prefix}-amazon-mq-credentials" }
}

resource "aws_secretsmanager_secret_version" "mq" {
  secret_id = aws_secretsmanager_secret.mq.id

  secret_string = jsonencode({
    username     = random_password.mq_user.result
    password     = random_password.mq_password.result
    engine       = "rabbitmq"
    host         = replace(replace(local.mq_endpoints[0], "amqps://", ""), ":5671", "")
    port         = 5671
    uri          = local.mq_endpoints[0]
    ssl_enabled  = "true"
    endpoint_url = local.mq_endpoints[0]
    endpoints    = local.mq_endpoints
  })
}

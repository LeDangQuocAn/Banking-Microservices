# ==============================================================
# Security Module — Security Groups
#
# Five security groups following least-privilege ingress:
#
#   alb-sg          — Internet-facing. Allows 80/443 from anywhere.
#   eks-node-sg     — Worker nodes. Ingress from ALB and self only.
#   rds-sg          — PostgreSQL 5432. Ingress from EKS nodes only.
#   elasticache-sg  — Redis 6379. Ingress from EKS nodes only.
#   documentdb-sg   — MongoDB 27017. Ingress from EKS nodes only.
#
# Rules use aws_vpc_security_group_ingress/egress_rule resources
# (AWS provider 5.x recommended pattern) instead of inline blocks
# to avoid state drift on external modifications.
# ==============================================================

# ===== ALB Security Group =====
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Internet-facing ALB: allows HTTP (80) and HTTPS (443) from anywhere. HTTP-to-HTTPS redirect is enforced at the ALB listener, not here."
  vpc_id      = var.vpc_id

  # create_before_destroy prevents downtime during SG replacements
  # (e.g. name change requires recreation).
  lifecycle { create_before_destroy = true }

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet - required for the ALB HTTP-to-HTTPS redirect listener."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb.id
  description       = "All outbound - allows ALB to forward requests to EKS pods on any port."
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
# ====== End of ALB Security Group =====


# ==============================================================
# EKS Node Security Group
#
# This is an additional SG applied alongside the EKS-managed
# cluster security group (which handles control-plane and node
# communication automatically). This SG handles:
#   - Node-to-node traffic (kubelet, CNI overlay, K8s services)
#   - ALB-to-pod traffic (AWS LBC forwards directly to pod IPs
#     in "ip" target type mode, on any containerPort)
# ==============================================================
resource "aws_security_group" "eks_node" {
  name        = "${local.name_prefix}-eks-node-sg"
  description = "Additional SG for EKS worker nodes. Allows inbound from ALB and self (node-to-node). Egress is unrestricted for ECR pulls and outbound API calls."
  vpc_id      = var.vpc_id

  lifecycle { create_before_destroy = true }

  tags = { Name = "${local.name_prefix}-eks-node-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "eks_node_self" {
  security_group_id            = aws_security_group.eks_node.id
  description                  = "Node-to-node: kubelet health checks, CNI overlay, K8s service traffic."
  referenced_security_group_id = aws_security_group.eks_node.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "eks_node_from_alb" {
  security_group_id            = aws_security_group.eks_node.id
  description                  = "ALB to pod: AWS Load Balancer Controller forwards to pod IPs on any containerPort (ip target type)."
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "eks_node_all_out" {
  security_group_id = aws_security_group.eks_node.id
  description       = "All outbound - needed for ECR image pulls, S3, Secrets Manager, EKS API server, and NAT to internet."
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


# ===== RDS Security Group (PostgreSQL — shared by all Java services) ======
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS PostgreSQL: allows port 5432 inbound from EKS worker nodes only. No egress - databases do not initiate connections."
  vpc_id      = var.vpc_id

  lifecycle { create_before_destroy = true }

  tags = { Name = "${local.name_prefix}-rds-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from EKS worker nodes."
  referenced_security_group_id = aws_security_group.eks_node.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
# ===== End of RDS Security Group =====

# ===== ElastiCache Security Group (Redis — caching layer) ======
resource "aws_security_group" "elasticache" {
  name        = "${local.name_prefix}-elasticache-sg"
  description = "ElastiCache Redis: allows port 6379 inbound from EKS worker nodes only. No egress."
  vpc_id      = var.vpc_id

  lifecycle { create_before_destroy = true }

  tags = { Name = "${local.name_prefix}-elasticache-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_from_eks" {
  security_group_id            = aws_security_group.elasticache.id
  description                  = "Redis from EKS worker nodes."
  referenced_security_group_id = aws_security_group.eks_node.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_from_vpc_cidr" {
  security_group_id = aws_security_group.elasticache.id
  description       = "Redis from within the VPC as a fallback for pod-to-cache traffic."
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}
# ===== End of ElastiCache Security Group =====

# ===== DocumentDB Security Group (MongoDB-compatible — log-service) ======
resource "aws_security_group" "documentdb" {
  name        = "${local.name_prefix}-documentdb-sg"
  description = "DocumentDB (MongoDB): allows port 27017 inbound from EKS worker nodes only. No egress."
  vpc_id      = var.vpc_id

  lifecycle { create_before_destroy = true }

  tags = { Name = "${local.name_prefix}-documentdb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "documentdb_from_eks" {
  security_group_id            = aws_security_group.documentdb.id
  description                  = "MongoDB protocol from EKS worker nodes (used by log-service)."
  referenced_security_group_id = aws_security_group.eks_node.id
  from_port                    = 27017
  to_port                      = 27017
  ip_protocol                  = "tcp"
}
# ===== End of DocumentDB Security Group =====
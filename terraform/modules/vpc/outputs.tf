# ==============================================================
# VPC Module — Outputs
# Downstream modules (security, eks, rds, elasticache, documentdb)
# consume these values; do not remove without checking references.
# ==============================================================

# ===== VPC =====
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "Primary IPv4 CIDR block of the VPC. Used by security groups to define intra-VPC ingress rules."
  value       = aws_vpc.main.cidr_block
}

# ===== Subnets =====
output "public_subnet_ids" {
  description = "IDs of public subnets (ALB, NAT Gateway), ordered by AZ."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets (EKS nodes, RDS, caches), ordered by AZ."
  value       = aws_subnet.private[*].id
}

# ===== Route Tables =====
output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables (1 for Dev, 1-per-AZ for Prod)."
  value       = aws_route_table.private[*].id
}

# ===== NAT Gateway =====
output "nat_gateway_ids" {
  description = "IDs of NAT Gateways."
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "Elastic IP addresses of NAT Gateways. Add these to any external service allowlists (third-party APIs, on-prem firewalls, etc.)."
  value       = aws_eip.nat[*].public_ip
}

# ==============================================================
# Security Module — Input Variables
# ==============================================================

# ===== Identity =====

variable "project" {
  description = "Project name — used to construct resource Name tags and KMS alias prefixes."
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. Dev, Prod) — used in resource Name tags."
  type        = string
}

# ===== Networking (sourced from vpc module outputs) =====

variable "vpc_id" {
  description = "VPC ID into which security groups are deployed."
  type        = string
}

variable "vpc_cidr" {
  description = "Primary CIDR block of the VPC. Used to scope intra-VPC ingress rules on database and cache security groups."
  type        = string
}

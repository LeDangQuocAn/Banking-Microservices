# ==============================================================
# RDS Module — Input Variables
# ==============================================================

# ===== Identity =====
variable "project" {
  description = "Project name — used to construct resource Name tags."
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. Dev, Prod) — used in resource Name tags."
  type        = string
}

# ===== Networking (sourced from vpc module outputs) =====
variable "private_subnet_ids" {
  description = "IDs of private subnets for the DB subnet group. Requires at least 2 subnets in different AZs."
  type        = list(string)
}

# ===== Security (sourced from security module outputs) =====
variable "kms_key_arn" {
  description = "ARN of the CMK used for RDS storage encryption at rest."
  type        = string
}

variable "sg_id" {
  description = "ID of the security group that restricts RDS access to EKS worker nodes only (port 5432)."
  type        = string
}

# ===== Engine =====
variable "engine_version" {
  description = "PostgreSQL major version string (e.g. \"15\"). AWS selects the latest patch release automatically. If you pass \"15.4\", the major version \"15\" is extracted for the parameter group family."
  type        = string
  default     = "15"
}

variable "db_name" {
  description = "Name of the initial database created on the RDS instance."
  type        = string
}

variable "db_username" {
  description = "Master username for the PostgreSQL instance. The password is auto-generated and stored in Secrets Manager — never supply it as a variable."
  type        = string
}

# ===== Sizing =====
variable "instance_class" {
  description = "RDS instance class (e.g. db.t3.micro for Dev, db.t3.medium for Prod)."
  type        = string
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB. Storage autoscaling can grow it up to 100 GiB automatically."
  type        = number
  default     = 20
}

# ===== Availability / Durability =====
variable "multi_az" {
  description = "Enable Multi-AZ standby replica for automatic failover. Set false for Dev cost savings; set true for Prod."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Days to retain automated backups. 0 disables backups (do not use in Prod)."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip taking a final snapshot when the instance is destroyed. Set true only for Dev environments."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying the RDS instance. Enable in Prod."
  type        = bool
  default     = false
}

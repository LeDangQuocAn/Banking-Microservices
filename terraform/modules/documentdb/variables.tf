# ==============================================================
# DocumentDB Module — Input Variables
#
# Used by: log-service (MongoDB driver, port 27017)
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
  description = "IDs of private subnets for the DocumentDB subnet group."
  type        = list(string)
}

# ===== Security (sourced from security module outputs) =====
variable "kms_key_arn" {
  description = "ARN of the CMK used for DocumentDB at-rest encryption."
  type        = string
}

variable "sg_id" {
  description = "ID of the security group that restricts DocumentDB access to EKS worker nodes only (port 27017)."
  type        = string
}

# ===== Engine =====
variable "engine_version" {
  description = "DocumentDB engine version (e.g. \"5.0\"). Determines the parameter group family (docdb5.0)."
  type        = string
  default     = "5.0"
}

variable "master_username" {
  description = "Master username for the DocumentDB cluster. The password is auto-generated and stored in Secrets Manager."
  type        = string
  default     = "docdbadmin"
}

# ===== Sizing =====
variable "instance_class" {
  description = "Instance class for DocumentDB nodes (e.g. db.t3.medium for Dev, db.r5.large for Prod)."
  type        = string
}

variable "instance_count" {
  description = "Number of instances in the cluster. Use 1 for Dev; use 2+ for read-scaling and failover in Prod."
  type        = number
  default     = 1
}

# ===== Availability / Durability =====
variable "backup_retention_days" {
  description = "Days to retain automated backups. 0 disables backups."
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Skip taking a final cluster snapshot on deletion. Set true only for Dev environments."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying the DocumentDB cluster. Enable in Prod."
  type        = bool
  default     = false
}

variable "secret_recovery_window_days" {
  description = "Days Secrets Manager waits before permanently deleting the secret on destroy."
  type        = number
  default     = 0
}

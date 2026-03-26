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

# ===== KMS =====
variable "kms_key_deletion_window_days" {
  description = "Waiting period (in days) before a scheduled KMS key deletion takes effect. Minimum 7, maximum 30. Use 7 for Dev (faster cleanup across destroy cycles); 30 for Prod."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_days >= 7 && var.kms_key_deletion_window_days <= 30
    error_message = "kms_key_deletion_window_days must be between 7 and 30 (AWS minimum and maximum)."
  }
}

# ==============================================================
# ElastiCache Module — Input Variables
#
# Used by: caching layer across banking microservices
#          (session tokens, rate limiting, frequently-read data)
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
  description = "IDs of private subnets for the ElastiCache subnet group."
  type        = list(string)
}

# ===== Security (sourced from security module outputs) =====
variable "kms_key_arn" {
  description = "ARN of the CMK used for ElastiCache at-rest encryption."
  type        = string
}

variable "sg_id" {
  description = "ID of the security group that restricts Redis access to EKS worker nodes only (port 6379)."
  type        = string
}

# ===== Engine =====
variable "engine_version" {
  description = "Redis engine version (e.g. \"7.1\"). The major version determines the parameter group family (redis7)."
  type        = string
  default     = "7.1"
}

variable "port" {
  description = "Port Redis listens on."
  type        = number
  default     = 6379
}

# ===== Sizing =====
variable "node_type" {
  description = "ElastiCache node type (e.g. cache.t3.micro for Dev, cache.t3.small for Prod)."
  type        = string
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the replication group. Use 1 for Dev; use 2 for Prod (automatic failover requires >= 2 nodes)."
  type        = number
  default     = 1
}

# ===== Availability / Durability =====
variable "automatic_failover_enabled" {
  description = "Enable automatic failover to a read replica on primary failure. Requires num_cache_nodes >= 2. Set false for single-node Dev cluster."
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain daily snapshots. 0 disables snapshots."
  type        = number
  default     = 1
}

variable "secret_recovery_window_days" {
  description = "Days Secrets Manager waits before permanently deleting the secret on destroy."
  type        = number
  default     = 0
}

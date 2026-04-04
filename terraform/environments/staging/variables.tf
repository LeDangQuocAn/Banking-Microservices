variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-southeast-1"
}

# ===== VPC module variables =====
variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC."
  type        = string
}

variable "azns" {
  description = "Availability Zone names for subnet placement."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT Gateway), one per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS nodes, RDS, caches), one per AZ."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway to reduce cost (Dev). Set false for per-AZ HA in Prod."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name — subnets are tagged with this value for Kubernetes ALB and node discovery."
  type        = string
}
# ===== End of VPC module variables =====

# ===== EKS module variables =====
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (e.g. \"1.32\"). Pin this to avoid unexpected upgrades."
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public K8s API endpoint. Restrict to known IPs in Prod."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
}

variable "node_disk_size_gb" {
  description = "Root EBS volume size in GiB per worker node."
  type        = number
  default     = 50
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
}
# ===== End of EKS module variables =====

# ===== RDS module variables =====
variable "rds_instance_class" {
  description = "RDS instance class (e.g. db.t3.micro for Dev, db.t3.medium for Prod)."
  type        = string
}

variable "rds_engine_version" {
  description = "PostgreSQL major version string (e.g. \"15\")."
  type        = string
  default     = "15"
}

variable "rds_db_name" {
  description = "Name of the initial database created on the RDS instance."
  type        = string
}

variable "rds_db_username" {
  description = "Master username for the RDS PostgreSQL instance."
  type        = string
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ standby. false for Dev, true for Prod."
  type        = bool
  default     = false
}

variable "rds_allocated_storage" {
  description = "Initial RDS allocated storage in GiB."
  type        = number
  default     = 20
}

variable "rds_backup_retention_days" {
  description = "Days to retain RDS automated backups."
  type        = number
  default     = 1
}

variable "rds_skip_final_snapshot" {
  description = "Skip final RDS snapshot on destroy. true for Dev only."
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Prevent Terraform from destroying the RDS instance."
  type        = bool
  default     = false
}

variable "rds_secret_recovery_window_days" {
  description = "Days Secrets Manager waits before permanently deleting the RDS secret on destroy. 0 for Dev, 7 for Prod."
  type        = number
  default     = 0
}
# ===== End of RDS module variables =====

# ===== DocumentDB module variables =====
variable "docdb_instance_class" {
  description = "DocumentDB instance class (e.g. db.t3.medium for Dev, db.r5.large for Prod)."
  type        = string
}

variable "docdb_instance_count" {
  description = "Number of DocumentDB cluster instances. 1 for Dev, 2+ for Prod."
  type        = number
  default     = 1
}

variable "docdb_engine_version" {
  description = "DocumentDB engine version (e.g. \"5.0\")."
  type        = string
  default     = "5.0"
}

variable "docdb_secret_recovery_window_days" {
  description = "Days Secrets Manager waits before permanently deleting the DocumentDB secret on destroy. 0 for Dev, 7 for Prod."
  type        = number
  default     = 0
}

variable "create_documentdb" {
  description = "Set to false to skip DocumentDB cluster creation. Required for free-tier or basic-plan AWS accounts that do not support the DocumentDB engine type (only aurora-postgresql is available on those plans)."
  type        = bool
  default     = true
}
# ===== End of DocumentDB module variables =====

# ===== ElastiCache module variables =====
variable "elasticache_node_type" {
  description = "ElastiCache node type (e.g. cache.t3.micro for Dev, cache.t3.small for Prod)."
  type        = string
}

variable "elasticache_num_cache_nodes" {
  description = "Number of ElastiCache Redis cache nodes. 1 for Dev, 2 for Prod."
  type        = number
  default     = 1
}

variable "elasticache_engine_version" {
  description = "ElastiCache Redis engine version (e.g. \"7.1\")."
  type        = string
  default     = "7.1"
}

variable "elasticache_secret_recovery_window_days" {
  description = "Days Secrets Manager waits before permanently deleting the ElastiCache secret on destroy. 0 for Dev, 7 for Prod."
  type        = number
  default     = 0
}
# ===== End of ElastiCache module variables ======

# ===== ECR module variables =====
variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability. MUTABLE for Dev (allows re-pushing 'latest'); IMMUTABLE for Prod (write-once tags, supply-chain integrity)."
  type        = string
  default     = "MUTABLE"
}

variable "ecr_max_tagged_image_count" {
  description = "Maximum number of tagged images to retain per ECR repository."
  type        = number
  default     = 10
}

variable "ecr_force_delete" {
  description = "If true, Terraform will delete ECR repositories even when they still contain images. Enables terraform destroy for iterative dev/prod cycles. In a real production environment, set this to false to prevent accidental image loss."
  type        = bool
  default     = true
}
# ===== End of ECR module variables =====
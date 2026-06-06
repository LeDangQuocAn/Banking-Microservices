aws_region = "ap-southeast-1"

# ===== VPC =====
vpc_cidr             = "10.1.0.0/16"
azns                 = ["ap-southeast-1a", "ap-southeast-1b"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
single_nat_gateway   = false # Per-AZ NAT — no single point of failure
cluster_name         = "banking-ms-prod"
# ===== End of VPC =====

# ===== EKS =====
cluster_version                      = "1.34"
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # TODO: restrict to VPN/office CIDR before go-live
node_instance_type                   = "t3.medium"   # Cost-optimised for DevSecOps project; upgrade to t3.large for real production workloads
node_disk_size_gb                    = 50
node_desired_size                    = 2
node_min_size                        = 2
node_max_size                        = 4
# ===== End of EKS =====

# ===== RDS =====
rds_instance_class              = "db.t3.micro" # Cost-optimised; upgrade to db.t3.medium for real production workloads
rds_engine_version              = "15"
rds_db_name                     = "bankingdb"
rds_db_username                 = "bankingadmin"
rds_multi_az                    = true # Synchronous standby in second AZ
rds_allocated_storage           = 20
rds_backup_retention_days       = 7
rds_skip_final_snapshot         = true # Academic simulation: destroy cleanly without final snapshot
rds_deletion_protection         = false
rds_secret_recovery_window_days = 0 # Academic simulation: immediate secret deletion for repeated apply/destroy
# ===== End of RDS =====

# ===== DocumentDB =====
docdb_instance_class              = "db.t3.medium" # Cost-optimised; upgrade to db.r5.large for memory-intensive production workloads
docdb_instance_count              = 2              # Primary + 1 replica across 2 AZs
docdb_engine_version              = "5.0"
docdb_secret_recovery_window_days = 0 # Academic simulation: immediate secret deletion for repeated apply/destroy
# ===== End of DocumentDB =====

# ===== ElastiCache =====
elasticache_node_type                   = "cache.t3.micro" # Cost-optimised; upgrade to cache.t3.small for real production cache loads
elasticache_num_cache_nodes             = 2
elasticache_engine_version              = "7.1"
elasticache_automatic_failover_enabled  = true # Requires num_cache_nodes >= 2
elasticache_snapshot_retention_limit    = 0
elasticache_secret_recovery_window_days = 0 # Academic simulation: immediate secret deletion for repeated apply/destroy
# ===== End of ElastiCache =====

# ===== Amazon MQ =====
amazon_mq_engine_version              = "3.13"
amazon_mq_host_instance_type          = "mq.t3.micro"
amazon_mq_secret_recovery_window_days = 0
# ===== End of Amazon MQ =====

# ===== ECR =====
ecr_image_tag_mutability   = "IMMUTABLE" # Write-once tags; new digest requires new tag
ecr_max_tagged_image_count = 30
ecr_force_delete           = true # Allows terraform destroy even if repos contain images
# ===== End of ECR =====

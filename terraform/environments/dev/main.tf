# ===== Create VPC =====
module "vpc" {
  source = "../../modules/vpc"

  project      = "Banking-Microservices"
  env          = "Dev"
  cluster_name = var.cluster_name

  vpc_cidr             = var.vpc_cidr
  azns                 = var.azns
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}
# ===== End of VPC =====

# ===== Security (KMS keys, IAM roles, Security Groups) =====
module "security" {
  source = "../../modules/security"

  project = "Banking-Microservices"
  env     = "Dev"

  # Sourced from vpc module — passed straight through so security
  # groups are created inside the correct VPC.
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr

  # 7 days (AWS minimum) — fast cleanup across dev destroy cycles.
  # Staging pending-deletion keys do not affect re-apply (new keys are always created).
  kms_key_deletion_window_days = 7
}
# ===== End of Security =====

# ===== EKS (cluster, node group, add-ons) =====
module "eks" {
  source = "../../modules/eks"

  project      = "Banking-Microservices"
  env          = "Dev"
  cluster_name = var.cluster_name

  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Networking — sourced from vpc module
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Security — sourced from security module
  eks_cluster_role_arn    = module.security.eks_cluster_role_arn
  eks_node_group_role_arn = module.security.eks_node_group_role_arn
  eks_node_sg_id          = module.security.eks_node_sg_id
  eks_secrets_kms_key_arn = module.security.eks_secrets_kms_key_arn

  # Node sizing
  node_instance_type = var.node_instance_type
  node_disk_size_gb  = var.node_disk_size_gb
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size

  # Security module must be fully applied before EKS is created:
  # the cluster role policy attachment must exist before cluster creation,
  # and the CMK policy must exist before secrets encryption is configured.
  depends_on = [module.security]
}
# ===== End of EKS =====

# ===== RDS (PostgreSQL) =====
module "rds" {
  source = "../../modules/rds"

  project = "Banking-Microservices"
  env     = "Dev"

  # Networking — private subnets from vpc module
  private_subnet_ids = module.vpc.private_subnet_ids

  # Security — CMK and SG from security module
  kms_key_arn = module.security.rds_kms_key_arn
  sg_id       = module.security.rds_sg_id

  # Engine
  engine_version = var.rds_engine_version
  db_name        = var.rds_db_name
  db_username    = var.rds_db_username

  # Sizing
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  # Availability / Durability
  multi_az              = var.rds_multi_az
  backup_retention_days = var.rds_backup_retention_days
  skip_final_snapshot   = var.rds_skip_final_snapshot
  deletion_protection   = var.rds_deletion_protection

  # Secrets Manager
  secret_recovery_window_days = var.rds_secret_recovery_window_days

  # Security module must be applied first so the CMK and SG exist
  # before the DB instance attempts to use them.
  depends_on = [module.security]
}
# ===== End of RDS =====

# ===== DocumentDB (MongoDB-compatible) =====
# count = 0 when create_documentdb = false (free-tier accounts — see §16 Issue F).
module "documentdb" {
  count  = var.create_documentdb ? 1 : 0
  source = "../../modules/documentdb"

  project = "Banking-Microservices"
  env     = "Dev"

  # Networking
  private_subnet_ids = module.vpc.private_subnet_ids

  # Security
  kms_key_arn = module.security.documentdb_kms_key_arn
  sg_id       = module.security.documentdb_sg_id

  # Engine
  engine_version = var.docdb_engine_version

  # Sizing
  instance_class = var.docdb_instance_class
  instance_count = var.docdb_instance_count

  # Secrets Manager
  secret_recovery_window_days = var.docdb_secret_recovery_window_days

  depends_on = [module.security]
}
# ===== End of DocumentDB =====

# ===== ElastiCache (Redis) =====
module "elasticache" {
  source = "../../modules/elasticache"

  project = "Banking-Microservices"
  env     = "Dev"

  # Networking
  private_subnet_ids = module.vpc.private_subnet_ids

  # Security
  kms_key_arn = module.security.elasticache_kms_key_arn
  sg_id       = module.security.elasticache_sg_id

  # Engine
  engine_version = var.elasticache_engine_version

  # Sizing — single node for Dev; automatic_failover stays false
  node_type       = var.elasticache_node_type
  num_cache_nodes = var.elasticache_num_cache_nodes

  # Secrets Manager
  secret_recovery_window_days = var.elasticache_secret_recovery_window_days

  depends_on = [module.security]
}
# ===== End of ElastiCache =====

# ===== ECR (private container registries) =====
# service_names defaults to all 8 microservices defined in the module.
# No VPC or security module dependency — ECR is a regional AWS service
# accessed over the internet endpoint or via Interface VPC Endpoint.
module "ecr" {
  source = "../../modules/ecr"

  project = "Banking-Microservices"
  env     = "Dev"

  # Image settings
  image_tag_mutability = var.ecr_image_tag_mutability

  # Lifecycle
  max_tagged_image_count = var.ecr_max_tagged_image_count

  # Destroy
  force_delete = var.ecr_force_delete
}
# ===== End of ECR =====
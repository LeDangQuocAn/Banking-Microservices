resource "random_id" "id" {
  byte_length = 4
}
# ===== Create S3 bucket for Terraform state =====
resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-terraform-state-${random_id.id.hex}"

  lifecycle {
    prevent_destroy = true // Remember to remove this before if you're done with your project.
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.security.s3_state_kms_key_arn
    }
    bucket_key_enabled = true
  }

  # The security module must be applied first to provision the CMK.
  depends_on = [module.security]
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "terraform_state_enforce_tls" {
  bucket = aws_s3_bucket.terraform_state.id

  # Must depend on the public-access block; otherwise AWS rejects the policy
  # when block_public_policy is being applied simultaneously.
  depends_on = [aws_s3_bucket_public_access_block.terraform_state]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}
# ===== End of S3 bucket for Terraform state =====

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

  # Security module must be applied first so the CMK and SG exist
  # before the DB instance attempts to use them.
  depends_on = [module.security]
}
# ===== End of RDS =====

# ===== DocumentDB (MongoDB-compatible) =====
module "documentdb" {
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
}
# ===== End of ECR =====
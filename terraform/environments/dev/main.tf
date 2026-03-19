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
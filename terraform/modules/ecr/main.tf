# ==============================================================
# ECR Module — Private Repositories
#
# One repository per microservice, created via for_each so each
# resource has a stable address (aws_ecr_repository.main["log-service"]
# etc.) — enabling targeted plan/apply without touching other repos.
#
# Resource breakdown (3 × len(service_names) = 24 resources for 8 services):
#   aws_ecr_repository            — private repo, scan_on_push, mutability
#   aws_ecr_lifecycle_policy      — expire old/untagged images automatically
#   aws_ecr_repository_policy     — deny cross-account push; restrict pull to
#                                   current account only
#
# Design decisions:
#   • scan_on_push = true — Amazon Inspector scans every pushed image for
#     OS and package CVEs; findings appear in the ECR console and Security Hub.
#     No extra cost, no agent required.
#
#   • Lifecycle policy (two rules):
#       Rule 1 — expire tagged images when count > max_tagged_image_count.
#                Prevents unbounded storage growth in active CI pipelines.
#       Rule 2 — expire untagged images after untagged_expiry_days.
#                Cleans up layer cache intermediates from multi-stage builds
#                and images orphaned by re-tagging (e.g. moving 'latest').
#
#   • Repository policy (deny cross-account):
#       Explicit Deny on ecr:BatchImportUpstreamImage and ecr:PutImage for
#       any principal NOT in the current AWS account. This blocks:
#         - Supply chain attacks where an external account pushes a poisoned image
#         - Accidental cross-account CI pipelines writing to the wrong registry
#       The policy does NOT restrict pull — EKS nodes (same account) pull via
#       the node-group IAM role (AmazonEC2ContainerRegistryReadOnly).
#
#   • image_tag_mutability = MUTABLE  (Dev)  — allows re-pushing 'latest'
#                           IMMUTABLE (Prod) — tags are write-once; a new
#                             digest requires a new tag, giving a full audit
#                             trail of what is running where.
# ==============================================================

# ===== Locals and Data =====
locals {
  name_prefix = "${var.project}-${var.env}"
}
data "aws_caller_identity" "current" {}
# ===== End of Locals and Data =====

# ===== ECR Repositories =====
resource "aws_ecr_repository" "main" {
  for_each = toset(var.service_names)

  # Prefix with project+env to give each environment its own isolated set of
  # repos in the same AWS account. e.g. banking-microservices-dev-account-service
  # Destroying Dev removes only Dev repos; Prod repos are completely unaffected.
  name                 = "${lower(var.project)}-${lower(var.env)}-${each.key}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${lower(var.project)}-${lower(var.env)}-${each.key}" }
}
# ===== End of ECR Repositories =====

# ===== Lifecycle Policies =====
# Applied per repository via for_each — each policy document is identical
# but must be attached individually to each aws_ecr_repository resource.
resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = toset(var.service_names)
  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      {
        # Rule 1 — cap the number of retained tagged images.
        # When exceeding max_tagged_image_count tagged images,
        # the oldest tagged images (by push date) are expired first.
        rulePriority = 1
        description  = "Keep last ${var.max_tagged_image_count} tagged images; expire older ones."
        selection = {
          tagStatus   = "tagged"
          tagPatternList = ["*"]
          countType   = "imageCountMoreThan"
          countNumber = var.max_tagged_image_count
        }
        action = { type = "expire" }
      },
      {
        # Rule 2 — expire untagged images quickly.
        # Untagged images accumulate from: re-tagging (the old digest loses
        # its tag), multi-stage build cache layers pushed by some CI tools,
        # and failed pushes where only some layers landed.
        rulePriority = 2
        description  = "Expire untagged images after ${var.untagged_expiry_days} day(s)."
        selection = {
          tagStatus = "untagged"
          countType = "sinceImagePushed"
          countUnit = "days"
          countNumber = var.untagged_expiry_days
        }
        action = { type = "expire" }
      },
    ]
  })
}
# ===== End of Lifecycle Policies =====

# ===== Repository Policies =====
# Explicit Deny on cross-account push operations.
# Allows all principals in the current account and IAM users (EKS pull, CI push).
# Denies any principal from a foreign account.
resource "aws_ecr_repository_policy" "main" {
  for_each   = toset(var.service_names)
  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow all ECR actions for principals inside the current account.
        # This covers:
        #   - EKS node-group role: ecr:GetDownloadUrlForLayer, ecr:BatchGetImage, etc.
        #   - CI/CD role: ecr:PutImage, ecr:InitiateLayerUpload, etc.
        Sid    = "AllowCurrentAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "ecr:*"
        Resource = "*"
      },
      {
        # Explicit Deny for cross-account push operations.
        # Scoped to write operations only; cross-account pull is
        # also blocked by default (no Allow for foreign accounts).
        Sid    = "DenyCrossAccountPush"
        Effect = "Deny"
        Principal = "*"
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchImportUpstreamImage",
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}
# ===== End of Repository Policies =====

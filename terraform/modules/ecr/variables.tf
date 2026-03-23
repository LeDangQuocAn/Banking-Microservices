# ==============================================================
# ECR Module — Input Variables
# ==============================================================

# ===== Identity =====
variable "project" {
  description = "Project name — used to construct resource Name tags."
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. Dev, Prod) — used in resource Name tags and mutability setting."
  type        = string
}

# ===== Repositories =====
variable "service_names" {
  description = "Ordered list of microservice names. One ECR repository is created per entry. Names must be lowercase and may contain hyphens."
  type        = list(string)
  default = [
    "account-service",
    "api-gateway-service",
    "bank-service",
    "credit-card-service",
    "discovery-client-service",
    "invoice-service",
    "log-service",
    "user-service",
  ]
}

# ===== Image settings =====
variable "image_tag_mutability" {
  description = "Controls whether image tags can be overwritten. MUTABLE allows re-tagging (Dev: overwrite 'latest' easily). IMMUTABLE enforces versioned releases (Prod: prevents silent overwriting of deployed tags — a hard requirement for supply-chain integrity)."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

# ===== Lifecycle =====
variable "max_tagged_image_count" {
  description = "Maximum number of tagged images to retain per repository. Older tagged images beyond this count are expired. Recommended: 10 for Dev, 30 for Prod."
  type        = number
  default     = 10
}

variable "untagged_expiry_days" {
  description = "Days after which untagged images (pushed but never tagged, or orphaned by re-tagging) are deleted. Keeps repositories clean from CI/CD layer cache artifacts."
  type        = number
  default     = 1
}

variable "force_delete" {
  description = "If true, Terraform will delete ECR repositories even when they still contain images. Set true in both Dev and Prod to enable terraform destroy. NOTE: In a real production environment, set this to false to prevent accidental image loss."
  type        = bool
  default     = false
}

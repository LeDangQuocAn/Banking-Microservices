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
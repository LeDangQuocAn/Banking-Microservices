# ===== Identity =====
variable "project" {
  description = "Project name — used to construct resource Name tags."
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. Dev, Prod) — used in resource Name tags."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name. Subnets are tagged with this value so the Kubernetes cloud-provider and AWS Load Balancer Controller can discover them automatically."
  type        = string
}

# ===== VPC and Subnets =====
variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string
}

variable "azns" {
  description = "Ordered list of Availability Zone names to spread subnets across. Length must match public_subnet_cidrs and private_subnet_cidrs."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks for public subnets, one per AZ. These subnets host the Application Load Balancer and NAT Gateways."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR blocks for private subnets, one per AZ. These subnets host EKS worker nodes, RDS, ElastiCache, and DocumentDB."
  type        = list(string)
}

# ===== NAT Gateway =====
variable "single_nat_gateway" {
  description = "When true, a single shared NAT Gateway is created (cost-effective for Dev). When false, one NAT Gateway per AZ is provisioned for high availability (recommended for Prod)."
  type        = bool
  default     = false
}

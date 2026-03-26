# ==============================================================
# EKS Module — Input Variables
# ==============================================================

# ===== Identity =====
variable "project" {
  description = "Project name — used in resource Name tags and IAM role names."
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. Dev, Prod) — used in resource Name tags."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster. Must match the value used to tag VPC subnets for ALB and node discovery."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (e.g. \"1.32\"). Pin this explicitly; unexpected upgrades can break workloads."
  type        = string
}

# ===== Networking (sourced from vpc module outputs) =====
variable "private_subnet_ids" {
  description = "IDs of private subnets where worker nodes are launched. Nodes should not be in public subnets."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of public subnets. Passed alongside private subnets in the cluster vpc_config so the EKS control plane can create cross-AZ ENIs in all subnets."
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to call the public Kubernetes API endpoint. Default allows any IP; restrict to known office/VPN CIDRs in Prod."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ===== Security (sourced from security module outputs) =====
variable "eks_cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS control plane."
  type        = string
}

variable "eks_node_group_role_arn" {
  description = "ARN of the IAM role assumed by EKS worker nodes."
  type        = string
}

variable "eks_node_sg_id" {
  description = "ID of the additional security group attached to worker nodes (allows ALB→pod and node-to-node traffic)."
  type        = string
}

variable "eks_secrets_kms_key_arn" {
  description = "ARN of the CMK used for Kubernetes secrets envelope encryption."
  type        = string
}

# ===== Node Group Sizing =====
variable "node_instance_type" {
  description = "EC2 instance type for worker nodes (e.g. t3.medium for Dev, t3.large for Prod)."
  type        = string
}

variable "node_disk_size_gb" {
  description = "Root EBS volume size in GiB for each worker node. 50 GiB covers the OS, kubelet, container runtime, and typical image cache."
  type        = number
  default     = 50
}

variable "node_desired_size" {
  description = "Desired number of worker nodes in the managed node group."
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes — the auto-scaling floor."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes — the auto-scaling ceiling."
  type        = number
}

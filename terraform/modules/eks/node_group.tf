# ==============================================================
# EKS Module — Launch Template and Managed Node Group
# ==============================================================

# ==============================================================
# Launch Template
#
# Exists for two hardening reasons only — all other node
# configuration (instance type, AMI, scaling) is set on the
# node group resource to keep Terraform diffs clean:
#
#   1. IMDSv2 enforcement  — prevents SSRF attacks where a
#      compromised pod calls the EC2 Instance Metadata Service
#      (IMDS) and steals node-level IAM credentials. IMDSv2
#      requires a session token obtained via a PUT request,
#      which is blocked by most Kubernetes network policies and
#      CNI configurations. hop_limit=2 is required because
#      containers add one extra network hop.
#
#   2. Additional security group — attaches eks_node_sg_id on
#      top of the EKS-managed cluster security group so that
#      our ALB-to-pod and node-to-node rules apply. EKS still
#      attaches its own cluster SG automatically alongside this.
#
#   3. Root volume hardening — gp3 encrypted root disk sized
#      to accommodate the OS, kubelet, container runtime, and
#      typical image layer cache.
# ==============================================================
resource "aws_launch_template" "eks_node" {
  name        = "${local.name_prefix}-eks-node-lt"
  description = "Hardens EKS worker nodes: enforces IMDSv2, attaches additional SG, and encrypts root EBS volume."

  # IMDSv2 enforcement
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2          # 1 = host only; 2 = one container hop allowed
  }

  # Additional security group
  # EKS appends the cluster-managed SG to this list automatically.
  vpc_security_group_ids = [var.eks_node_sg_id]

  # Root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
      # Uses AWS-managed EBS key (aws/ebs). Upgrade to a CMK
      # by adding an ebs_volume KMS key in the security module
      # if node-level key audit control becomes a requirement.
    }
  }

  # EC2 instance name tag
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.name_prefix}-eks-node" }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${local.name_prefix}-eks-node-vol" }
  }

  lifecycle { create_before_destroy = true }
}

# ==============================================================
# Managed Node Group
#
# Nodes are placed in private subnets only — they must never
# have a direct public IP. All internet-bound traffic routes
# through the NAT Gateway provisioned in the VPC module.
#
# Rolling update strategy: max_unavailable = 1 ensures at least
# (desired - 1) nodes are always serving traffic during updates.
# ==============================================================
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = var.eks_node_group_role_arn

  # Worker nodes live in private subnets only.
  subnet_ids = var.private_subnet_ids

  # Instance configuration
  ami_type       = "AL2023_x86_64_STANDARD" # Amazon Linux 2023 (preferred over AL2 for EKS 1.29+)
  capacity_type  = "ON_DEMAND"
  instance_types = [var.node_instance_type]

  launch_template {
    id      = aws_launch_template.eks_node.id
    version = aws_launch_template.eks_node.latest_version
  }

  # Scaling configuration
  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # Rolling update strategy
  update_config {
    # Replace at most 1 node at a time — safe for a 2-node Dev
    # cluster; for Prod with larger groups consider max_unavailable_percentage.
    max_unavailable = 1
  }

  tags = { Name = "${local.name_prefix}-node-group" }
}

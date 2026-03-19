# ==============================================================
# Security Module — IAM Roles for EKS
#
# eks-cluster-role    — assumed by the EKS control plane.
#                       Grants AmazonEKSClusterPolicy only.
#
# eks-node-group-role — assumed by EC2 worker nodes.
#                       Grants the three minimum managed policies:
#                         • AmazonEKSWorkerNodePolicy
#                         • AmazonEKS_CNI_Policy
#                         • AmazonEC2ContainerRegistryReadOnly
#
# Principle of least privilege:
#   Nodes receive READ-ONLY ECR access; they never push images.
#   All write-capable operations (ECR push, Secrets Manager, S3)
#   are granted to pods via IRSA roles added in Phase 4, not here.
# ==============================================================

# ===== EKS Cluster Role =====
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.name_prefix}-eks-cluster-role"
  description        = "Assumed by the EKS control plane. Grants minimum permissions for cluster lifecycle management."
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = { Name = "${local.name_prefix}-eks-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
# ===== End of EKS Cluster Role =====

# ===== EKS Node Group Role =====
data "aws_iam_policy_document" "eks_node_group_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_node_group" {
  name               = "${local.name_prefix}-eks-node-group-role"
  description        = "Assumed by EKS worker nodes (EC2). Read-only ECR access; all write-capable pod permissions are handled by IRSA roles (Phase 4)."
  assume_role_policy = data.aws_iam_policy_document.eks_node_group_assume_role.json

  tags = { Name = "${local.name_prefix}-eks-node-group-role" }
}

# Allows nodes to register with the EKS cluster and call the DescribeCluster / DescribeNodegroup APIs.
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Allows the VPC CNI plugin (aws-node DaemonSet) to manage pod networking.
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Allows nodes to pull container images from ECR ONLY (CI/CD pipeline handles pushes).
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
# ====== End of EKS Node Group Role =====
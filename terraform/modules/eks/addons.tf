# ==============================================================
# EKS Module — Add-ons and EBS CSI Driver IRSA
#
# Add-ons managed here:
#   vpc-cni             — AWS VPC CNI: assigns VPC IPs to pods
#   coredns             — In-cluster DNS resolution
#   kube-proxy          — K8s Service iptables/ipvs rules on nodes
#   aws-ebs-csi-driver  — Dynamic EBS PersistentVolume provisioning
#
# Versions are resolved to the latest compatible release at plan
# time via data sources — no hardcoded version strings to forget
# to update. Override by removing most_recent and pinning
# addon_version explicitly when you need deterministic deploys.
#
# IRSA role for EBS CSI:
#   The EBS CSI driver controller runs in kube-system and needs
#   IAM permissions to create/attach/detach EBS volumes. Without
#   IRSA the pods would need to inherit broad node-level permissions.
#   The IRSA role is scoped to exactly the ebs-csi-controller-sa
#   service account in the kube-system namespace.
# ==============================================================

# ===== Add-on version resolution =====
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}
# ===== End of add-on version resolution =====

# ===== vpc-cni =====
# Installs the AWS VPC CNI DaemonSet. Each pod gets a real VPC IP
# from the node's ENI secondary IP pool, making pods routable
# within the VPC without NAT (required for ALB ip target mode).
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE" # Don't overwrite custom vpc-cni env vars on updates

  tags = { Name = "${local.name_prefix}-addon-vpc-cni" }
}
# ===== End of vpc-cni =====

# ===== coredns =====
# Cluster DNS — pods use CoreDNS to resolve Kubernetes Service
# names (e.g. postgres.default.svc.cluster.local) and external DNS.
# Must wait for nodes to be ready; DaemonSet requires schedulable nodes.
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = { Name = "${local.name_prefix}-addon-coredns" }

  # CoreDNS is a Deployment that requires schedulable nodes.
  depends_on = [aws_eks_node_group.main]
}
# ===== End of coredns =====

# ===== kube-proxy =====
# Maintains iptables/ipvs rules on each node so that traffic
# sent to a ClusterIP is forwarded to a backing pod endpoint.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = { Name = "${local.name_prefix}-addon-kube-proxy" }

  depends_on = [aws_eks_node_group.main]
}
# ===== End of kube-proxy =====

# ===== EBS CSI Driver IRSA =====
# The EBS CSI controller uses this role to call ec2:CreateVolume,
# ec2:AttachVolume, ec2:DeleteVolume, etc. The role is bound
# exclusively to the ebs-csi-controller-sa service account in
# kube-system via the OIDC subject condition below.
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Scope to exactly the EBS CSI controller service account —
    # no other pod in any namespace can assume this role.
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${local.name_prefix}-ebs-csi-driver-role"
  description        = "IRSA role for the EBS CSI driver controller in kube-system. Scoped to the ebs-csi-controller-sa service account via OIDC."
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = { Name = "${local.name_prefix}-ebs-csi-driver-role" }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
# ===== End of EBS CSI Driver IRSA =====

# ===== aws-ebs-csi-driver =====
# Enables dynamic EBS PersistentVolume provisioning for stateful
# workloads (RabbitMQ, Vault agent, any pod needing persistent disk).
# The IRSA role ARN is passed so the controller pod gets IAM access
# without any node-level permissions.
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi_driver.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn

  tags = { Name = "${local.name_prefix}-addon-ebs-csi-driver" }

  depends_on = [aws_eks_node_group.main]
}
# ===== End of aws-ebs-csi-driver =====
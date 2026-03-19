# ==============================================================
# VPC Module — Resources
# ==============================================================

# Resolves the current AWS region for constructing VPC Endpoint service names.
data "aws_region" "current" {}

# Local values for conditional logic and Don't repeat yourself (DRY) naming.
locals {
  # Dev  (single_nat_gateway = true)  → 1 NAT GW, 1 private route table
  # Prod (single_nat_gateway = false) → 1 NAT GW per AZ, 1 private RT per AZ
  nat_count   = var.single_nat_gateway ? 1 : length(var.azns)
  name_prefix = "${var.project}-${var.env}"
}

# ===== VPC =====
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # Both flags are required for EKS node registration and
  # for internal DNS resolution of RDS / ElastiCache endpoints.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}
# ===== End of VPC =====

# ===== Subnets — Public   (ALB, NAT Gateway) =====
resource "aws_subnet" "public" {
  count = length(var.azns)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azns[count.index]

  # EC2 instances launched here receive a public IP for the NAT Gateway and ALB nodes.
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"

    # AWS Load Balancer Controller uses this tag to discover which subnets to place internet-facing ALBs in.
    "kubernetes.io/role/elb" = "1"

    # Marks subnets as usable by the named EKS cluster.
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
# ===== End of Subnets — Public =====

# ===== Subnets — Private  (EKS nodes, RDS, ElastiCache, DocumentDB) =====
resource "aws_subnet" "private" {
  count = length(var.azns)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azns[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet-${count.index + 1}"

    # AWS Load Balancer Controller uses this tag to discover which subnets to place internal ALBs / NLBs in.
    "kubernetes.io/role/internal-elb" = "1"

    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
# ===== End of Subnets — Private =====

# ===== Internet Gateway   (outbound path for public subnets) =====
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}
# ===== End of Internet Gateway =====

# ===== NAT Gateway   (outbound path for private subnets) =====
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  # Elastic IPs must be allocated after the Internet Gateway is attached to the VPC
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-eip-nat-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id

  # NAT Gateways must be placed in a public subnet.
  subnet_id  = aws_subnet.public[count.index].id
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
  }
}
# ===== End of NAT Gateway =====

# ===== Route Tables — Public =====
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.azns)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
# ===== End of Route Tables — Public =====

# ===== Route Tables — Private =====
# One table per NAT Gateway:
#   Dev  (single_nat_gateway=true)  → 1 table shared by all private subnets
#   Prod (single_nat_gateway=false) → 1 table per AZ for traffic isolation
# ==============================================================
resource "aws_route_table" "private" {
  count  = local.nat_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.azns)

  subnet_id = aws_subnet.private[count.index].id

  # Dev:  both private subnets share rt[0] (single NAT)
  # Prod: each private subnet maps to its AZ-specific rt
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}
# ===== End of Route Tables — Private =====

# ===== VPC Endpoints =====
# S3 Gateway Endpoint — free of charge.
# Routes S3 traffic from all subnets directly over the AWS backbone,
# eliminating NAT Gateway data-processing fees for S3 access
# (Terraform state reads/writes, ECR layer pulls from S3, etc.).
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Attach to every route table so both public + private subnets benefit from direct S3 routing.
  route_table_ids = concat(
    [aws_route_table.public.id],
    [for rt in aws_route_table.private : rt.id],
  )

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}
# ===== End of VPC Endpoints =====

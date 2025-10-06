# --- VPC & Networking ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.app_name}-vpc" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.app_name}-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "${var.app_name}-subnet-2" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.app_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# --- ECR repository ---
resource "aws_ecr_repository" "repo" {
  name = var.app_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

# --- IAM Role: either create it or reference existing ---
resource "aws_iam_role" "eks_service_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.app_name}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_service_attach" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.eks_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Execution role for node / kube
resource "aws_iam_role" "eks_node_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.app_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_attach1" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_attach2" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_attach3" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# If not creating, reference existing role(s)
data "aws_iam_role" "existing_execution_role" {
  count = var.create_iam_role ? 0 : 1
  name  = var.existing_execution_role_name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "eks" {
  name     = "${var.app_name}-cluster"
  role_arn = data.aws_iam_role.existing_execution_role.arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }
}

# --- Node group (EC2) ---
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.app_name}-nodes"
  node_role_arn   = var.create_iam_role ? aws_iam_role.eks_node_role[0].arn : data.aws_iam_role.existing_execution_role[0].arn
  subnet_ids      = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  scaling_config {
    desired_size = var.node_group_desired_capacity
    min_size     = 1
    max_size     = 2
  }

  instance_types = [var.node_group_instance_type]
  ami_type       = "AL2_x86_64"
  depends_on     = [aws_eks_cluster.eks]
}

# --- Security group for worker -> allow port 8000 if needed (not strictly necessary for pods behind k8s services) ---
resource "aws_security_group" "workers_sg" {
  name   = "${var.app_name}-workers-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
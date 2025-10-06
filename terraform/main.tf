# --- Networking: default VPC and subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- ECR repository ---
resource "aws_ecr_repository" "repo" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- IAM: use existing LabRole ---
data "aws_iam_role" "existing_execution_role" {
  name = var.existing_execution_role_name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "eks" {
  name     = "${var.app_name}-cluster"
  role_arn = data.aws_iam_role.existing_execution_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
}

# --- Node Group (EC2) ---
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.app_name}-nodes"
  node_role_arn   = data.aws_iam_role.existing_execution_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = var.node_group_desired_capacity
    min_size     = 1
    max_size     = 2
  }

  instance_types = [var.node_group_instance_type]
  ami_type       = "AL2_x86_64"

  depends_on = [aws_eks_cluster.eks]
}

# --- Security Group for workers ---
resource "aws_security_group" "workers_sg" {
  name        = "${var.app_name}-workers-sg"
  description = "Allow traffic for worker nodes"
  vpc_id      = data.aws_vpc.default.id

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
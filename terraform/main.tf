data "aws_caller_identity" "current" {}

# --- Define el rol de laboratorio (LabRole) ---
locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}

# --- Networking (usa VPC por defecto) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "valid_for_eks" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
}

# --- ECR Repository ---
resource "aws_ecr_repository" "repo" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
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

# --- EKS Cluster ---
resource "aws_eks_cluster" "eks" {
  name     = "${var.app_name}-cluster"
  role_arn = local.lab_role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids         = data.aws_subnets.valid_for_eks.ids
    security_group_ids = [aws_security_group.workers_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }
}

# --- EKS Node Group ---
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.app_name}-nodes"
  node_role_arn   = local.lab_role_arn
  subnet_ids      = data.aws_subnets.valid_for_eks.ids
  instance_types  = [var.node_group_instance_type]

  scaling_config {
    desired_size = var.node_group_desired_capacity
    min_size     = 1
    max_size     = 2
  }

  ami_type      = "AL2_x86_64"
  capacity_type = "ON_DEMAND"

  depends_on = [aws_eks_cluster.eks]
}

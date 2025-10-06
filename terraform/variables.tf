variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name (used for resources)"
  type        = string
  default     = "backend-news-api"
}

variable "create_iam_role" {
  description = "If true, Terraform will create the ECS/EKS IAM role. Set to false in Learner Lab if you cannot create IAM roles."
  type        = bool
  default     = false
}

variable "existing_execution_role_name" {
  description = "If create_iam_role is false, the name of an existing IAM role to use (e.g., LabRole)."
  type        = string
  default     = "LabRole"
}

variable "node_group_desired_capacity" {
  description = "Desired EC2 nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "node_group_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.small"
}
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
output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "ecr_repo_url" {
  value = aws_ecr_repository.repo.repository_url
}

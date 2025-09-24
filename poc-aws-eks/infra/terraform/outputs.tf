output "cluster_name"     { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_version"  { value = module.eks.cluster_version }
output "region"           { value = var.aws_region }

output "vpc_id"           { value = module.vpc.vpc_id }
output "private_subnets"  { value = module.vpc.private_subnets }
output "public_subnets"   { value = module.vpc.public_subnets }

output "ecr_repo"         { value = aws_ecr_repository.repo.repository_url }

output "kubeconfig_cmd" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

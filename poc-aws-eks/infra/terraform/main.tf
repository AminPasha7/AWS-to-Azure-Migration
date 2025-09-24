############################
# VPC (terraform-aws-modules)
############################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

############################
# EKS (terraform-aws-eks)
############################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name                    = var.project_name
  cluster_version                 = var.kubernetes_version
  cluster_endpoint_public_access  = true

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets

  cluster_enabled_log_types       = ["api","audit","authenticator","controllerManager","scheduler"]

  eks_managed_node_groups = {
    cpu = {
      instance_types = [var.cpu_instance_type]
      min_size       = var.cpu_min
      desired_size   = var.cpu_desired
      max_size       = var.cpu_max
      labels         = { "workload" = "cpu" }
    }
    gpu = {
      instance_types = [var.gpu_instance_type]
      min_size       = var.gpu_min
      desired_size   = var.gpu_desired    # 0 by default
      max_size       = var.gpu_max
      taints         = [{ key = "nvidia.com/gpu", value = "present", effect = "NO_SCHEDULE" }]
      labels         = { "workload" = "gpu" }
    }
  }

  tags = var.tags
}

############################
# ECR + lifecycle policy
############################
resource "aws_ecr_repository" "repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration { scan_on_push = true }
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "untagged_cleanup" {
  repository = aws_ecr_repository.repo.name
  policy     = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Expire untagged images after 7 days",
      selection    = {
        tagStatus   = "untagged",
        countType   = "sinceImagePushed",
        countUnit   = "days",
        countNumber = 7
      },
      action = { type = "expire" }
    }]
  })
}

############################
# CloudWatch Logs group
############################
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}/cluster"
  retention_in_days = 14
  tags              = var.tags
}

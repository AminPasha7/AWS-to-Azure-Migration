# AWS PoC Scaffold (VPC + EKS + ECR + Logs) for migration demo
$Project = "poc-aws-eks"; $F=@{
  "$Project/.gitignore"=@'
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
crash.log
.env
'@;

  "$Project/README.md"=@'
AWS PoC for Migration (VPC + EKS + ECR)
=======================================

Minimal but realistic AWS stack you can later migrate to Azure AKS/ACR.

What it creates
- VPC (10.0.0.0/16), 2 public + 2 private subnets, IGW, NAT
- EKS Cluster with:
  - CPU node group: t3.medium (desired=1)
  - GPU node group defined (p3.2xlarge) with desired=0 (no cost until scaled)
- ECR repo with lifecycle policy (untagged images expire after 7 days)
- CloudWatch control-plane logs for EKS

Quick start
1) cd infra/terraform
2) terraform init
3) terraform apply -auto-approve
4) Run scripts/eks-get-kubeconfig.ps1
5) Run scripts/deploy-sample.ps1
6) kubectl -n demo port-forward svc/demo 8080:80  (open http://localhost:8080)

Clean up
- scripts/cleanup.ps1

Cost note
- EKS control plane (~$74/mo) + 1× t3.medium (~$0.0416/hr). Keep up only while testing, then destroy.
'@;

  "$Project/infra/terraform/versions.tf"=@'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
'@;

  "$Project/infra/terraform/providers.tf"=@'
provider "aws" {
  region = var.aws_region
}
data "aws_availability_zones" "available" {}
'@;

  "$Project/infra/terraform/variables.tf"=@'
variable "project_name" { type = string  default = "poc-eks" }
variable "aws_region"   { type = string  default = "us-east-1" }

variable "vpc_cidr"     { type = string  default = "10.0.0.0/16" }
variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24","10.0.2.0/24"]
}
variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24","10.0.12.0/24"]
}

# EKS
variable "kubernetes_version" { type = string default = "1.29" }

# CPU node group
variable "cpu_instance_type"  { type = string default = "t3.medium" }
variable "cpu_desired"        { type = number default = 1 }
variable "cpu_min"            { type = number default = 1 }
variable "cpu_max"            { type = number default = 2 }

# GPU node group (defined but size=0)
variable "gpu_instance_type"  { type = string default = "p3.2xlarge" }
variable "gpu_desired"        { type = number default = 0 }
variable "gpu_min"            { type = number default = 0 }
variable "gpu_max"            { type = number default = 2 }

# ECR
variable "ecr_repo_name"      { type = string default = "poc-nginx" }

variable "tags" {
  type = map(string)
  default = {
    project = "aws-migration-poc"
    owner   = "amin"
    env     = "poc"
  }
}
'@;

  "$Project/infra/terraform/main.tf"=@'
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
'@;

  "$Project/infra/terraform/outputs.tf"=@'
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
'@;

  "$Project/scripts/eks-get-kubeconfig.ps1"=@'
param(
  [string]$Region = "us-east-1",
  [string]$ClusterName = "poc-eks"
)
aws eks update-kubeconfig --name $ClusterName --region $Region
kubectl cluster-info
'@;

  "$Project/k8s/demo.yaml"=@'
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels: { app: demo }
  template:
    metadata:
      labels: { app: demo }
    spec:
      containers:
        - name: nginx
          image: public.ecr.aws/nginx/nginx:1.25
          ports: [ { containerPort: 80 } ]
          readinessProbe:
            httpGet: { path: "/", port: 80 }
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet: { path: "/", port: 80 }
            initialDelaySeconds: 10
            periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: demo
  namespace: demo
spec:
  type: ClusterIP
  selector: { app: demo }
  ports:
    - port: 80
      targetPort: 80
'@;

  "$Project/scripts/deploy-sample.ps1"=@'
# Deploy sample app to EKS (no ELB cost)
kubectl apply -f ../k8s/demo.yaml
kubectl -n demo rollout status deploy/demo
kubectl -n demo get svc demo -o wide
Write-Host ""
Write-Host "Port-forward with:"
Write-Host "kubectl -n demo port-forward svc/demo 8080:80"
'@;

  "$Project/scripts/cleanup.ps1"=@'
# Tears down the entire PoC (be sure you are in the right directory!)
$TerraformDir = Join-Path (Split-Path $PSScriptRoot -Parent) "infra/terraform"
Push-Location $TerraformDir
try {
  kubectl delete -f ../../k8s/demo.yaml --ignore-not-found | Out-Null
  terraform destroy -auto-approve
} finally {
  Pop-Location
}
'@;
}

# Create folders and files
$F.Keys | ForEach-Object {
  $p = $_; $d = Split-Path -Parent $p
  if ($d -and -not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  Set-Content -Path $p -Value $F[$p] -Encoding UTF8
}

"`nScaffold created at: $(Resolve-Path $Project)`nNext steps:
1) cd $Project/infra/terraform
2) terraform init
3) terraform apply -auto-approve
4) ../../scripts/eks-get-kubeconfig.ps1
5) ../../scripts/deploy-sample.ps1
6) kubectl -n demo port-forward svc/demo 8080:80   # open http://localhost:8080

Cleanup later:  $Project/scripts/cleanup.ps1
"

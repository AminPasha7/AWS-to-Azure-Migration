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

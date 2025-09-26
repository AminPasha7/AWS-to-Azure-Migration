variable "project" {
  description = "Project prefix used for resource naming."
  type        = string
  default     = "aws2azure"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "aks_node_size" {
  description = "VM size for AKS default node pool."
  type        = string
  default     = "Standard_DS2_v2"
}

variable "aks_node_count" {
  description = "Node count for default pool."
  type        = number
  default     = 2
}

variable "kubernetes_version" {
  description = "AKS version (optional; set null for latest default)."
  type        = string
  default     = null
}

variable "vnet_cidr" {
  type        = string
  description = "VNet address space."
  default     = "10.40.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet for AKS nodes."
  default     = "10.40.1.0/24"
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    workload = "aws-to-azure-migration-poc"
    env      = "poc"
  }
}

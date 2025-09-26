terraform {
  required_version = ">= 1.6.0"

  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "aws-to-azure/azure/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

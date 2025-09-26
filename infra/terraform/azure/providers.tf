variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID (optional if using environment)."
  default     = null
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id != null ? var.subscription_id : null
}

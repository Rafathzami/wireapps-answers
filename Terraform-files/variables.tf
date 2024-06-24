variable "resource_group_name" {
  description = "resource group name"
  default     = "wire-apps-rg"
}

variable "location" {
  description = "Azure region"
  default     = "East US"
}

variable "acr_name" {
  description = "Azure Container Registry"
  default     = "wireappsacr"
}

variable "postgresql_admin_password" {
  description = "Admin Password"
  default     = "Admin@123123!"
  sensitive   = true
}

variable "resource_group" {
  description = "Resource group object."
  type = object({
    name     = string
    location = string
  })
}

variable "project" {
  description = "Short project identifier."
  type        = string
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}

variable "server_name" {
  description = "Unique name for this MySQL server."
  type        = string
}

variable "admin_username" {
  description = "MySQL admin username."
  type        = string
  default     = "mysqladmin"
}

variable "admin_password" {
  description = "MySQL admin password. Must be strong and kept secret."
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "MySQL SKU name (e.g. B_Standard_B2ms, GP_Standard_D2ds_v5)."
  type        = string
  default     = "B_Standard_B2ms"
}

variable "storage_mb" {
  description = "Storage size in MB."
  type        = number
  default     = 32768
}

variable "databases" {
  description = "List of database names to create on this server."
  type        = list(string)
  default     = []
}

variable "allowed_cidrs" {
  description = "Additional CIDRs allowed to connect."
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet ID for VNet-integrated access (optional)."
  type        = string
  default     = ""
}

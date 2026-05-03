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
  description = "Unique name for this PostgreSQL server."
  type        = string
}

variable "admin_username" {
  description = "PostgreSQL admin username."
  type        = string
  default     = "pgadmin"
}

variable "admin_password" {
  description = "PostgreSQL admin password. Must be provided and kept secret."
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name (e.g. B2ms, D2ds_v5)."
  type        = string
  default     = "B2ms"
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
  description = "Additional CIDRs allowed to connect (beyond the VNet rule)."
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet ID for VNet-integrated access."
  type        = string
  default     = ""
}

variable "enable_pgvector" {
  description = "Enable pgvector extension."
  type        = bool
  default     = true
}

variable "enable_pgbouncer" {
  description = "Enable pgbouncer (server parameter)."
  type        = bool
  default     = true
}

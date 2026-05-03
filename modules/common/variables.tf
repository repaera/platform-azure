variable "project" {
  description = "Short project identifier used in resource names (e.g. myapp, client-x)."
  type        = string
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name applied to tags."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

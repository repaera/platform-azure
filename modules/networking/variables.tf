variable "resource_group" {
  description = "Resource group object from modules/common."
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

variable "vnet_address_space" {
  description = "CIDR block for the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "CIDR block for the node subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation for SSH access."
  type        = string
}

variable "management_cidr" {
  description = "CIDR allowed to access K8s API (6443) and Rancher dashboard (8443). Defaults to SSH source if not set."
  type        = string
  default     = ""
}

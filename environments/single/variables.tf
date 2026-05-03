variable "project" {
  description = "Short project identifier used in resource names."
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

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation for SSH access."
  type        = string
}

variable "management_cidr" {
  description = "CIDR allowed to access K8s API (6443) and Rancher (8443). Defaults to SSH source if not set."
  type        = string
  default     = ""
}

variable "vm_size" {
  description = "Azure VM size for the single node."
  type        = string
  default     = "Standard_D4as_v5"
}

variable "admin_username" {
  description = "SSH admin username."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file. Generate a dedicated key: ssh-keygen -t ed25519 -C 'platform-azure-infra' -f ~/.ssh/platform-azure-infra"
  type        = string
}



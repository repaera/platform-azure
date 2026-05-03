variable "project" {
  description = "Short project identifier used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name applied to tags."
  type        = string
  default     = "staging"
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

variable "server_count" {
  description = "Number of k3s control plane nodes. Must be odd (1, 3, 5...) for etcd quorum."
  type        = number
  default     = 1

  validation {
    condition     = var.server_count >= 1 && var.server_count % 2 == 1
    error_message = "Server count must be odd and >= 1."
  }
}

variable "server_vm_size" {
  description = "VM size for control plane nodes. Light workloads only."
  type        = string
  default     = "Standard_D2as_v5"
}

variable "agent_count" {
  description = "Number of worker/agent nodes. Can be any number >= 0."
  type        = number
  default     = 1

  validation {
    condition     = var.agent_count >= 0
    error_message = "Agent count must be >= 0."
  }
}

variable "agent_vm_size" {
  description = "VM size for worker nodes. Hosts apps, Redis, OpenSearch."
  type        = string
  default     = "Standard_D2as_v5"
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

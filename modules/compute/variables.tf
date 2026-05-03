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

variable "node_names" {
  description = "List of stable node names (e.g. [\"node-0\", \"node-1\"])."
  type        = list(string)
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_D2as_v5"
}

variable "zones" {
  description = "Availability zones. If empty, no zone assignment."
  type        = list(string)
  default     = []
}

variable "admin_username" {
  description = "SSH admin username."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "subnet_id" {
  description = "Subnet ID for NICs."
  type        = string
}

variable "nsg_id" {
  description = "NSG ID for NIC association."
  type        = string
}

variable "enable_public_ip" {
  description = "Assign a public IP to each node."
  type        = bool
  default     = true
}

variable "associate_lb" {
  description = "Associate NICs with a load balancer backend pool."
  type        = bool
  default     = false
}

variable "lb_pool_id" {
  description = "Load balancer backend pool ID. Required if associate_lb is true."
  type        = string
  default     = ""
}

variable "os_disk_type" {
  description = "OS disk storage account type. Premium_LRS for production, Standard_LRS for dev/cost savings."
  type        = string
  default     = "Premium_LRS"
}

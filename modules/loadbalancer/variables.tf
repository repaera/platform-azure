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

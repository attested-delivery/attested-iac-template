variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "name" {
  description = "Base name for the example workload."
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

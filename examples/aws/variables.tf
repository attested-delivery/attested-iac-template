variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
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

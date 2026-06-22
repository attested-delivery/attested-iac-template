variable "project" {
  description = "GCP project ID to deploy into."
  type        = string
  default     = "example-project"
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "us-central1"
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

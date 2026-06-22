variable "name" {
  description = "Base name for the workload; used as the resource name prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 chars, lowercase alphanumeric or hyphen, start with a letter, and not end with a hyphen."
  }
}

variable "managed_by" {
  description = "Value for the standard `managed-by` tag. Defaults to opentofu; set to \"terraform\" (or your tool) for accurate inventory when the engine differs."
  type        = string
  default     = "opentofu"
}

variable "environment" {
  description = "Deployment environment (drives the standard `environment` tag)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "extra_tags" {
  description = "Additional tags merged over the standard set (caller wins on key conflicts)."
  type        = map(string)
  default     = {}
}

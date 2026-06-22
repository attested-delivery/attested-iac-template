# Provider + engine version constraints for the labels module.
#
# Creditless by design: the module depends only on the `random` provider, which
# runs entirely locally (no cloud account, no network calls at apply time). This
# lets the template's own CI `validate` the module with zero credentials while
# still exercising real provider pinning and a committed `.terraform.lock.hcl`.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

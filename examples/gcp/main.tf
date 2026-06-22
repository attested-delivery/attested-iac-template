# GCP example root — consumes the labels module and provisions a single,
# secure-by-default Cloud Storage bucket. Validate-only in CI (no credentials).

provider "google" {
  project = var.project
  region  = var.region
}

module "labels" {
  source      = "../../modules/labels"
  name        = var.name
  environment = var.environment
}

# trivy:ignore:AVD-GCP-0066 Demo uses Google-managed encryption; a CMEK key is environment-specific.
# trivy:ignore:AVD-GCP-0077 Access logging requires a separate log-sink bucket; out of scope for a demo.
resource "google_storage_bucket" "this" {
  # Minimal creditless demo bucket (see the AWS example for the rationale).
  #checkov:skip=CKV_GCP_62:Access logging requires a separate log-destination bucket
  name     = module.labels.name_prefix
  location = var.region
  labels   = module.labels.tags

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }
}

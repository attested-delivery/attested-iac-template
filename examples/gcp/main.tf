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

resource "google_storage_bucket" "this" {
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

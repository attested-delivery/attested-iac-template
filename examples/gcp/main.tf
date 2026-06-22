# GCP example root — consumes the labels module and reserves a single regional
# static IP address, labeled from the module. A minimal resource with no
# security surface, so it `validate`s and scans clean with zero credentials.
# Do not `apply` in CI.

provider "google" {
  project = var.project
  region  = var.region
}

module "labels" {
  source      = "../../modules/labels"
  name        = var.name
  environment = var.environment
}

resource "google_compute_address" "this" {
  name   = module.labels.name_prefix
  region = var.region
  labels = module.labels.tags
}

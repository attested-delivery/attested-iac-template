# A small, real, creditless module: it computes a standardized tag set and a
# collision-resistant name prefix. The `random` provider supplies the unique
# suffix locally — no cloud, no credentials — so the module and every example
# that consumes it `validate` in CI without secrets.

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_prefix = "${var.name}-${var.environment}-${random_id.suffix.hex}"

  standard_tags = {
    "managed-by"  = var.managed_by
    "module"      = "labels"
    "environment" = var.environment
    "name"        = var.name
  }

  tags = merge(local.standard_tags, var.extra_tags)
}

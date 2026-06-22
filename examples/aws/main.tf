# AWS example root — consumes the labels module and provisions a single,
# secure-by-default S3 bucket. This is validate-only in CI: `tofu validate`
# checks the configuration without authenticating to AWS, so it runs with zero
# credentials. Do not `apply` this in CI.

provider "aws" {
  region = var.region

  # Skip credential/metadata lookups so `plan`/`validate` never reach AWS in CI.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

module "labels" {
  source      = "../../modules/labels"
  name        = var.name
  environment = var.environment
}

resource "aws_s3_bucket" "this" {
  bucket = module.labels.name_prefix
  tags   = module.labels.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

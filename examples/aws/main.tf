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

# trivy:ignore:AVD-AWS-0089
resource "aws_s3_bucket" "this" {
  # This is a minimal, creditless example bucket whose purpose is to demonstrate
  # consuming the labels module under the attested pipeline — not production
  # storage. The operational best-practices below are out of scope for a
  # single-resource demo and are suppressed with cause (real workloads should
  # enable them):
  #checkov:skip=CKV_AWS_18:Access logging requires a separate log-destination bucket
  #checkov:skip=CKV_AWS_144:Cross-region replication requires a second-region bucket + IAM role
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration is environment-specific
  #checkov:skip=CKV2_AWS_62:Event notifications require an SNS/SQS/Lambda target
  bucket = module.labels.name_prefix
  tags   = module.labels.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# trivy:ignore:AVD-AWS-0132 Demo uses AWS-managed KMS; a customer-managed key is environment-specific.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  #checkov:skip=CKV_AWS_145:Demo uses AWS-managed KMS (aws:kms); a CMK is environment-specific
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

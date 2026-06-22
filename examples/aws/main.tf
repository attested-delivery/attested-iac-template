# AWS example root — consumes the labels module and creates a single Resource
# Groups group that collects resources by the module's standard tags. A logical
# grouping with no security surface, so it `validate`s and scans clean with zero
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

resource "aws_resourcegroups_group" "this" {
  name = module.labels.name_prefix
  tags = module.labels.tags

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [{
        Key    = "environment"
        Values = [module.labels.tags["environment"]]
      }]
    })
  }
}

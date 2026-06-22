# Azure example root — consumes the labels module and provisions a single
# resource group. Validate-only in CI (no credentials).

provider "azurerm" {
  features {}

  # Lets `validate` run without authenticating to Azure in CI. A real deployment
  # supplies credentials via ARM_* env vars or OIDC and a real subscription_id.
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
  resource_provider_registrations = "none"
}

module "labels" {
  source      = "../../modules/labels"
  name        = var.name
  environment = var.environment
}

resource "azurerm_resource_group" "this" {
  name     = module.labels.name_prefix
  location = var.location
  tags     = module.labels.tags
}

# TFLint configuration. Uses only the bundled `terraform` ruleset (no external
# plugin downloads, no cloud credentials), so `tflint` runs offline in CI across
# the module and every example. Cloud-provider rulesets (aws/google/azurerm)
# are intentionally not enabled here — they need provider context the
# validate-only CI does not have; enable them per-project when you deploy.

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

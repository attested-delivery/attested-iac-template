output "tags" {
  description = "Standardized tag map (standard tags merged with extra_tags)."
  value       = local.tags
}

output "name_prefix" {
  description = "Collision-resistant name prefix: <name>-<environment>-<random>."
  value       = local.name_prefix
}

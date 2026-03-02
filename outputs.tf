output "azure_dynamic_role_name" {
  description = "Name of the Azure dynamic credentials role."
  value       = length(vault_azure_secret_backend_role.this) > 0 ? var.azure_dynamic_spn_role_name : null
}

output "azure_static_role_name" {
  description = "Name of the Azure static credentials role."
  value       = length(vault_azure_secret_backend_static_role.static_role) > 0 ? var.azure_static_spn_role_name : null
}

output "demo_script_dynamic_approle_name" {
  description = "Name of the AppRole for the dynamic credentials demo script."
  value       = var.enable_demo_resources && length(vault_approle_auth_backend_role.demo_script_dynamic) > 0 ? var.demo_script_dynamic_approle_name : null
}

output "demo_script_dynamic_role_id" {
  description = "AppRole Role ID for the dynamic credentials demo script. Use this with Secret ID to authenticate."
  value       = var.enable_demo_resources && length(vault_approle_auth_backend_role.demo_script_dynamic) > 0 ? vault_approle_auth_backend_role.demo_script_dynamic[0].role_id : null
}

output "demo_script_static_approle_name" {
  description = "Name of the AppRole for the static credentials demo script."
  value       = var.enable_demo_resources && length(vault_approle_auth_backend_role.demo_script_static) > 0 ? var.demo_script_static_approle_name : null
}

output "demo_script_static_role_id" {
  description = "AppRole Role ID for the static credentials demo script. Use this with Secret ID to authenticate."
  value       = var.enable_demo_resources && length(vault_approle_auth_backend_role.demo_script_static) > 0 ? vault_approle_auth_backend_role.demo_script_static[0].role_id : null
}

output "namespace_path" {
  description = "Path of the Vault namespace where all resources are created."
  value       = vault_namespace.azureengine_demo.path
}

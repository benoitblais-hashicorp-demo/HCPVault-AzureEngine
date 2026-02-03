output "vault_approle_role_id" {
  description = "Role ID for AppRole azure-reader."
  value       = vault_approle_auth_backend_role.azure_reader.role_id
}

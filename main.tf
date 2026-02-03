# Enable Azure secrets engine
resource "vault_azure_secret_backend" "azure" {
  path               = var.azure_secret_backend_path
  client_id          = var.azure_client_id
  client_secret      = var.azure_client_secret
  subscription_id    = var.azure_subscription_id
  tenant_id          = var.azure_tenant_id
  identity_token_ttl = var.azure_identity_token_ttl
  rotation_window    = var.azure_rotation_window
  rotation_schedule  = var.azure_rotation_schedule
}

# Create a role for existing Azure AD Application Object ID
resource "vault_azure_secret_backend_role" "existing_object_id" {
  backend               = vault_azure_secret_backend.azure.path
  role                  = var.azure_spn_role_name
  application_object_id = var.azure_spn_object_id
  ttl                   = var.azure_spn_ttl
  max_ttl               = var.azure_spn_max_ttl
}

# Vault AppRole auth backend for script access
resource "vault_auth_backend" "approle" {
  type = "approle"
  path = var.vault_approle_auth_backend_path
}

resource "vault_approle_auth_backend_role" "azure_reader" {
  backend        = var.vault_approle_auth_backend_path
  role_name      = var.vault_approle_role_name
  token_policies = var.vault_approle_token_policies
  token_ttl      = var.vault_approle_token_ttl
  token_max_ttl  = var.vault_approle_token_max_ttl
}


# Vault policy to allow read access only to the Azure role secret
resource "vault_policy" "azure_spn_reader" {
  name   = var.azure_spn_reader_policy_name
  policy = <<EOT
path "${vault_azure_secret_backend.azure.path}/creds/${var.azure_spn_role_name}" {
  capabilities = ["read"]
}
EOT
}

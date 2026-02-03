# Enable Azure secrets engine
resource "vault_azure_secret_backend" "this" {
  count = var.azure_client_id != "" && var.azure_client_id != null ? 1 : 0

  path               = var.azure_secret_backend_path
  client_id          = var.azure_client_id
  client_secret      = var.azure_client_secret
  subscription_id    = var.azure_subscription_id
  tenant_id          = var.azure_tenant_id
  identity_token_ttl = var.azure_identity_token_ttl
  rotation_window    = var.azure_rotation_window
  rotation_schedule  = var.azure_rotation_schedule
}

# Create a role to generate dynamic credentials for existing Azure AD Application Object ID
resource "vault_azure_secret_backend_role" "this" {
  count = length(vault_azure_secret_backend.this) > 0 && var.azure_dynamic_spn_object_id != "" && var.azure_dynamic_spn_object_id != null ? 1 : 0

  backend               = vault_azure_secret_backend.this[0].path
  role                  = var.azure_dynamic_spn_role_name
  application_object_id = var.azure_dynamic_spn_object_id
  ttl                   = var.azure_dynamic_spn_ttl
  max_ttl               = var.azure_dynamic_spn_max_ttl
}

# Create a role to generate static credentials for existing Azure AD Application Object ID
resource "vault_azure_secret_backend_static_role" "static_role" {
  count = length(vault_azure_secret_backend.this) > 0 && var.azure_static_spn_object_id != "" && var.azure_static_spn_object_id != null ? 1 : 0

  backend               = vault_azure_secret_backend.this[0].path
  role                  = var.azure_static_spn_role_name
  application_object_id = var.azure_static_spn_object_id
  ttl                   = var.azure_static_spn_ttl
}

# Enable AppRole auth backend for demo script
resource "vault_auth_backend" "approle" {
  count = var.enable_demo_resources ? 1 : 0

  type = "approle"
  path = var.approle_backend_path
}

# Create policy for demo script to read Azure dynamic credentials
resource "vault_policy" "demo_script_dynamic" {
  count = var.enable_demo_resources && length(vault_azure_secret_backend.this) > 0 ? 1 : 0

  name = var.demo_script_dynamic_policy_name

  policy = <<EOF
# Allow reading dynamic Azure credentials
path "${var.azure_secret_backend_path}/creds/${var.azure_dynamic_spn_role_name}" {
  capabilities = ["read"]
}

# Allow listing Azure roles
path "${var.azure_secret_backend_path}/roles" {
  capabilities = ["list"]
}
EOF
}

# Create AppRole role for dynamic credentials demo script
resource "vault_approle_auth_backend_role" "demo_script_dynamic" {
  count = var.enable_demo_resources && length(vault_azure_secret_backend.this) > 0 && length(vault_auth_backend.approle) > 0 ? 1 : 0

  backend        = vault_auth_backend.approle[0].path
  role_name      = var.demo_script_dynamic_approle_name
  token_policies = [vault_policy.demo_script_dynamic[0].name]

  token_ttl     = var.demo_script_token_ttl
  token_max_ttl = var.demo_script_token_max_ttl

  bind_secret_id = true
  secret_id_ttl  = var.demo_script_secret_id_ttl
}

# Create policy for demo script to read Azure static credentials
resource "vault_policy" "demo_script_static" {
  count = var.enable_demo_resources && length(vault_azure_secret_backend.this) > 0 ? 1 : 0

  name = var.demo_script_static_policy_name

  policy = <<EOF
# Allow reading static Azure credentials
path "${var.azure_secret_backend_path}/static-creds/${var.azure_static_spn_role_name}" {
  capabilities = ["read"]
}

# Allow listing Azure roles
path "${var.azure_secret_backend_path}/roles" {
  capabilities = ["list"]
}
EOF
}

# Create AppRole role for static credentials demo script
resource "vault_approle_auth_backend_role" "demo_script_static" {
  count = var.enable_demo_resources && length(vault_azure_secret_backend.this) > 0 && length(vault_auth_backend.approle) > 0 ? 1 : 0

  backend        = vault_auth_backend.approle[0].path
  role_name      = var.demo_script_static_approle_name
  token_policies = [vault_policy.demo_script_static[0].name]

  token_ttl     = var.demo_script_token_ttl
  token_max_ttl = var.demo_script_token_max_ttl

  bind_secret_id = true
  secret_id_ttl  = var.demo_script_secret_id_ttl
}
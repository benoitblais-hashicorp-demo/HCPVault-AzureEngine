# Enable Azure secrets engine
resource "vault_azure_secret_backend" "azure" {
	path               = "azure"
  client_id          = var.azure_client_id
	client_secret      = var.azure_client_secret
	subscription_id    = var.azure_subscription_id
	tenant_id          = var.azure_tenant_id
  identity_token_ttl =  "3600"         # 1 hour (best practice)
  rotation_period    =  "86400"        # 24 hours (best practice)
  rotation_window    =  "3600"         # 1 hour window (best practice)
  rotation_schedule  =  "0 */24 * * *"  # Every 24 hours
}

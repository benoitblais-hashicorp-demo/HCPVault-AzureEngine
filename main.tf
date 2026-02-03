# Enable Azure secrets engine
resource "vault_azure_secret_backend" "azure" {
	path            = "azure"
	subscription_id = var.azure_subscription_id
	tenant_id       = var.azure_tenant_id
	client_id       = var.azure_client_id
	client_secret   = var.azure_client_secret
}

# Azure root credential rotation role
resource "vault_azure_secret_backend_role" "root_rotation" {
	backend         = vault_azure_secret_backend.azure.path
	role            = "root"
	application_object_id = var.azure_client_id
	ttl             = "24h" # Rotate every 24 hours
}

# Schedule rotation of Azure root credentials
resource "vault_azure_secret_backend_rotation" "root" {
	backend = vault_azure_secret_backend.azure.path
	role    = vault_azure_secret_backend_role.root_rotation.role
	interval = "24h"
}

variable "azure_client_id" {
	type        = string
	description = "(Required) Azure Client ID for Vault Azure secrets engine."
}

variable "azure_client_secret" {
	type        = string
	description = "(Required) Azure Client Secret for Vault Azure secrets engine."
	sensitive   = true
}

variable "azure_subscription_id" {
	type        = string
	description = "(Required) Azure Subscription ID for Vault Azure secrets engine."
}

variable "azure_tenant_id" {
	type        = string
	description = "(Required) Azure Tenant ID for Vault Azure secrets engine."
}

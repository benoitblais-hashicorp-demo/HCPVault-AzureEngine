variable "azure_client_id" {
  type        = string
  description = "(Required) Azure Client ID for Vault Azure secrets engine."
}

variable "azure_client_secret" {
  type        = string
  description = "(Required) Azure Client Secret for Vault Azure secrets engine."
  sensitive   = true
}

variable "azure_spn_object_id" {
  type        = string
  description = "(Required) Azure AD Application Object ID for the SPN role."
}

variable "azure_subscription_id" {
  type        = string
  description = "(Required) Azure Subscription ID for Vault Azure secrets engine."
}

variable "azure_tenant_id" {
  type        = string
  description = "(Required) Azure Tenant ID for Vault Azure secrets engine."
}

variable "azure_identity_token_ttl" {
  type        = number
  description = "(Optional) TTL for identity tokens issued by the backend (in seconds)."
  default     = 3600
}

variable "azure_rotation_schedule" {
  type        = string
  description = "(Optional) Cron schedule for root credential rotation."
  default     = "0 */24 * * *"
}

variable "azure_rotation_window" {
  type        = number
  description = "(Optional) Window for root credential rotation (in seconds)."
  default     = 3600
}

variable "azure_secret_backend_path" {
  type        = string
  description = "(Optional) Path to enable the Azure secrets engine in Vault."
  default     = "azure"
}

variable "azure_spn_role_name" {
  type        = string
  description = "(Optional) Name of the Azure SPN role for Vault."
  default     = "HCPVault-Demo-ExistingObjectID"
}

variable "azure_spn_max_ttl" {
  type        = number
  description = "(Optional) Max TTL for the SPN role credentials."
  default     = 600
}

variable "azure_spn_reader_policy_name" {
  type        = string
  description = "(Optional) Name of the Vault policy for SPN secret read access."
  default     = "azure-spn-reader-policy"
}

variable "azure_spn_ttl" {
  type        = number
  description = "(Optional) TTL for the SPN role credentials."
  default     = 300
}

variable "vault_approle_auth_backend_path" {
  type        = string
  description = "(Optional) Path to enable the Vault AppRole auth backend."
  default     = "approle"
}

variable "vault_approle_role_name" {
  type        = string
  description = "(Optional) Name of the Vault AppRole role."
  default     = "azure-reader"
}

variable "vault_approle_token_policies" {
  type        = list(string)
  description = "(Optional) List of policies to attach to the AppRole token."
  default     = ["default"]
}

variable "vault_approle_token_max_ttl" {
  type        = number
  description = "(Optional) Max TTL for the AppRole token (in seconds)."
  default     = 7200
}

variable "vault_approle_token_ttl" {
  type        = number
  description = "(Optional) TTL for the AppRole token (in seconds)."
  default     = 3600
}

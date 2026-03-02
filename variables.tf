variable "approle_backend_path" {
  type        = string
  description = "(Optional) Path where AppRole auth backend is mounted in Vault."
  default     = "approle"
}

variable "azure_client_id" {
  type        = string
  description = "(Optional) Azure Client ID for Vault Azure secrets engine. If provided, `azure_client_secret`, `azure_subscription_id`, and `azure_tenant_id` must also be provided."
  default     = ""

  validation {
    condition     = var.azure_client_id == "" || (var.azure_client_id != "" && var.azure_client_secret != "" && var.azure_subscription_id != "" && var.azure_tenant_id != "")
    error_message = "When `azure_client_id` is provided, `azure_client_secret`, `azure_subscription_id`, and `azure_tenant_id` must also be provided."
  }

  validation {
    condition     = var.azure_client_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_client_id))
    error_message = "The `azure_client_id` must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_client_secret" {
  type        = string
  description = "(Optional if azure_client_id is provided) Azure Client Secret for Vault Azure secrets engine."
  default     = ""
  sensitive   = true

  validation {
    condition     = var.azure_client_secret == "" || length(var.azure_client_secret) >= 8
    error_message = "The `azure_client_secret` must be at least 8 characters long."
  }
}

variable "azure_dynamic_spn_max_ttl" {
  type        = number
  description = "(Optional) Max TTL for the SPN role for dynamic credentials. Default is 600 seconds."
  default     = 600

  validation {
    condition     = var.azure_dynamic_spn_max_ttl > 0
    error_message = "The `azure_dynamic_spn_max_ttl` must be greater than 0."
  }
}

variable "azure_dynamic_spn_object_id" {
  type        = string
  description = "(Optional) Azure AD Application Object ID for the SPN role with dynamic credentials."
  default     = ""

  validation {
    condition     = var.azure_dynamic_spn_object_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_dynamic_spn_object_id))
    error_message = "The `azure_dynamic_spn_object_id` must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_dynamic_spn_role_name" {
  type        = string
  description = "(Optional) Name of the Azure SPN role for Vault for dynamic credentials."
  nullable    = false
  default     = "HCPVault-Demo-Dynamic"
}

variable "azure_dynamic_spn_ttl" {
  type        = number
  description = "(Optional) TTL for the SPN role for dynamic credentials. Default is 300 seconds."
  default     = 300

  validation {
    condition     = var.azure_dynamic_spn_ttl > 0
    error_message = "The `azure_dynamic_spn_ttl` must be greater than 0."
  }

  validation {
    condition     = var.azure_dynamic_spn_ttl <= var.azure_dynamic_spn_max_ttl
    error_message = "The `azure_dynamic_spn_ttl` must be less than or equal to `azure_dynamic_spn_max_ttl`."
  }
}

variable "azure_identity_token_ttl" {
  type        = number
  description = "(Optional) TTL for identity tokens issued by the backend (in seconds). Default is 3600 seconds."
  default     = 3600

  validation {
    condition     = var.azure_identity_token_ttl > 0
    error_message = "The `azure_identity_token_ttl` must be greater than 0."
  }
}

variable "azure_rotation_schedule" {
  type        = string
  description = "(Optional) Cron schedule for root credential rotation. Default is \"0 */24 * * *\"."
  default     = "0 */24 * * *"

  validation {
    condition     = can(regex("^([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)$", var.azure_rotation_schedule))
    error_message = "The `azure_rotation_schedule` must be a valid cron-style schedule with 5 space-separated fields (minute hour day month weekday)."
  }
}

variable "azure_rotation_window" {
  type        = number
  description = "(Optional) Window for root credential rotation (in seconds). Default is 3600 seconds."
  default     = 3600

  validation {
    condition     = var.azure_rotation_window > 0
    error_message = "The `azure_rotation_window` must be greater than 0."
  }
}

variable "azure_secret_backend_path" {
  type        = string
  description = "(Optional) Path to enable the Azure secrets engine in Vault."
  nullable    = false
  default     = "azure"
}

variable "azure_static_spn_object_id" {
  type        = string
  description = "(Optional) Azure AD Application Object ID for the SPN role with static credentials."
  default     = ""

  validation {
    condition     = var.azure_static_spn_object_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_static_spn_object_id))
    error_message = "The `azure_static_spn_object_id` must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_static_spn_role_name" {
  type        = string
  description = "(Optional) Name of the Azure SPN role for Vault for static credentials."
  nullable    = false
  default     = "HCPVault-Demo-Static"
}

variable "azure_static_spn_ttl" {
  type        = number
  description = "(Optional) TTL for the SPN role for static credentials. Default is 1 year (31536000 seconds)."
  default     = 31536000

  validation {
    condition     = var.azure_static_spn_ttl > 0
    error_message = "The `azure_static_spn_ttl` must be greater than 0."
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "(Optional if azure_client_id is provided) Azure Subscription ID for Vault Azure secrets engine."
  default     = ""

  validation {
    condition     = var.azure_subscription_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_subscription_id))
    error_message = "The `azure_subscription_id` must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_tenant_id" {
  type        = string
  description = "(Optional if azure_client_id is provided) Azure Tenant ID for Vault Azure secrets engine."
  default     = ""

  validation {
    condition     = var.azure_tenant_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_tenant_id))
    error_message = "The `azure_tenant_id` must be a valid GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "demo_script_dynamic_approle_name" {
  type        = string
  description = "(Optional) Name of the AppRole for the dynamic credentials demo script."
  default     = "azure-demo-script-dynamic"
}

variable "demo_script_dynamic_policy_name" {
  type        = string
  description = "(Optional) Name of the policy for the dynamic credentials demo script."
  default     = "azure-demo-script-dynamic-policy"
  nullable    = false
}

variable "demo_script_secret_id_ttl" {
  type        = number
  description = "(Optional) TTL for AppRole Secret ID in seconds. Default is 0 (no expiration)."
  default     = 0

  validation {
    condition     = var.demo_script_secret_id_ttl >= 0
    error_message = "The `demo_script_secret_id_ttl` must be greater than or equal to 0."
  }
}

variable "demo_script_static_approle_name" {
  type        = string
  description = "(Optional) Name of the AppRole for the static credentials demo script."
  nullable    = false
  default     = "azure-demo-script-static"
}

variable "demo_script_static_policy_name" {
  type        = string
  description = "(Optional) Name of the policy for the static credentials demo script."
  nullable    = false
  default     = "azure-demo-script-static-policy"
}

variable "demo_script_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum TTL for tokens issued to the demo script in seconds. Default is 3600 (1 hour)."
  default     = 3600

  validation {
    condition     = var.demo_script_token_max_ttl > 0
    error_message = "The `demo_script_token_max_ttl` must be greater than 0."
  }
}

variable "demo_script_token_ttl" {
  type        = number
  description = "(Optional) TTL for tokens issued to the demo script in seconds. Default is 1800 (30 minutes)."
  default     = 1800

  validation {
    condition     = var.demo_script_token_ttl > 0
    error_message = "The `demo_script_token_ttl` must be greater than 0."
  }

  validation {
    condition     = var.demo_script_token_ttl <= var.demo_script_token_max_ttl
    error_message = "The `demo_script_token_ttl` must be less than or equal to `demo_script_token_max_ttl`."
  }
}

variable "enable_demo_resources" {
  type        = bool
  description = "(Optional) Enable creation of demo script resources (AppRole backend, role, and policy). Default is true."
  default     = true
}

variable "namespace_path" {
  type        = string
  description = "(Optional) Path for the Vault namespace where all resources will be created."
  default     = "azureengine-demo"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.namespace_path))
    error_message = "The `namespace_path` can only contain alphanumeric characters, hyphens, and underscores."
  }
}

<!-- BEGIN_TF_DOCS -->

# HCP Vault Azure Secret Engine

This Terraform module provisions and manages the Vault Azure secrets engine, supporting secure dynamic credential generation, automated
root credential rotation, and least-privilege access for Azure resources. The module integrates with Azure using a Service Principal
(SPN) and Vault AppRole authentication, following best practices for secret management and automation.

## Permissions

### Vault

- Requires capability to enable and configure the Azure secrets engine (`update`, `create`, `read`, `delete` on `sys/mounts` and `azure/*`).
- Requires ability to create, update, and delete secret backend roles (`create`, `update`, `read`, `delete` on `azure/roles/*`).
- Requires ability to manage credential rotation schedules and policies (`update`, `read` on `azure/*`).
- Requires ability to configure and manage AppRole authentication (`create`, `update`, `read`, `delete` on `auth/approle/*`).
- Requires ability to create and manage Vault policies for least-privilege access (`create`, `update`, `read`, `delete` on `sys/policy/*`).

## Authentication

Authentication to Vault can be configured using one of the following methods:

- **VAULT\_TOKEN**: Set the `VAULT_TOKEN` environment variable with a valid Vault token
- **VAULT\_ADDR**: Set the `VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **VAULT\_NAMESPACE**: Set to `admin` to provision resources in the admin namespace

Example:

```bash
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_TOKEN="your-vault-token"
export VAULT_NAMESPACE="admin"
```

## Features

- Enables Vault Azure secrets engine for dynamic credential management
- All backend, role, and policy attributes are configurable via variables for maximum flexibility
- Securely stores Azure credentials using sensitive Terraform variables
- Automates root credential rotation on a schedule (default: every 24 hours, configurable)
- Supports custom roles and policies for fine-grained access control
- Provides Vault AppRole authentication for scripts and automation
- Follows best practices for secret management and security

## Prerequisites

### Azure Service Principal (SPN)

An Azure Service Principal (SPN) is required for the Vault Azure secrets engine to securely authenticate and interact with Azure
resources. The SPN enables Vault to dynamically generate, rotate, and revoke credentials for applications and users, ensuring
least-privilege access and automated credential lifecycle management. The permissions granted to the SPN determine which Azure resources
Vault can manage and what operations it can perform.

- **Required API permissions:**
  - `Microsoft.Authorization/roleAssignments/read`
  - `Microsoft.Authorization/roleAssignments/write`
  - `Microsoft.Authorization/roleAssignments/delete`
  - `Microsoft.Resources/subscriptions/resourceGroups/read`
  - `Microsoft.Resources/subscriptions/resourceGroups/write`
  - `Microsoft.Resources/subscriptions/resourceGroups/delete`
  - `Microsoft.Compute/*` (if managing VMs)
- **Required Azure Role:**
  - `Owner` or `Contributor` on the target subscription/resource group
- The SPN must have permission to create, update, and delete role assignments for dynamic credential management.

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (5.6.0)

## Modules

No modules.

## Required Inputs

The following input variables are required:

### <a name="input_azure_client_id"></a> [azure\_client\_id](#input\_azure\_client\_id)

Description: (Required) Azure Client ID for Vault Azure secrets engine.

Type: `string`

### <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret)

Description: (Required) Azure Client Secret for Vault Azure secrets engine.

Type: `string`

### <a name="input_azure_spn_object_id"></a> [azure\_spn\_object\_id](#input\_azure\_spn\_object\_id)

Description: (Required) Azure AD Application Object ID for the SPN role.

Type: `string`

### <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id)

Description: (Required) Azure Subscription ID for Vault Azure secrets engine.

Type: `string`

### <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id)

Description: (Required) Azure Tenant ID for Vault Azure secrets engine.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_azure_identity_token_ttl"></a> [azure\_identity\_token\_ttl](#input\_azure\_identity\_token\_ttl)

Description: (Optional) TTL for identity tokens issued by the backend (in seconds).

Type: `number`

Default: `3600`

### <a name="input_azure_rotation_period"></a> [azure\_rotation\_period](#input\_azure\_rotation\_period)

Description: (Optional) Period for root credential rotation (in seconds).

Type: `number`

Default: `86400`

### <a name="input_azure_rotation_window"></a> [azure\_rotation\_window](#input\_azure\_rotation\_window)

Description: (Optional) Window for root credential rotation (in seconds).

Type: `number`

Default: `3600`

### <a name="input_azure_secret_backend_path"></a> [azure\_secret\_backend\_path](#input\_azure\_secret\_backend\_path)

Description: (Optional) Path to enable the Azure secrets engine in Vault.

Type: `string`

Default: `"azure"`

### <a name="input_azure_spn_max_ttl"></a> [azure\_spn\_max\_ttl](#input\_azure\_spn\_max\_ttl)

Description: (Optional) Max TTL for the SPN role credentials.

Type: `number`

Default: `600`

### <a name="input_azure_spn_reader_policy_name"></a> [azure\_spn\_reader\_policy\_name](#input\_azure\_spn\_reader\_policy\_name)

Description: (Optional) Name of the Vault policy for SPN secret read access.

Type: `string`

Default: `"azure-spn-reader-policy"`

### <a name="input_azure_spn_role_name"></a> [azure\_spn\_role\_name](#input\_azure\_spn\_role\_name)

Description: (Optional) Name of the Azure SPN role for Vault.

Type: `string`

Default: `"HCPVault-Demo-ExistingObjectID"`

### <a name="input_azure_spn_ttl"></a> [azure\_spn\_ttl](#input\_azure\_spn\_ttl)

Description: (Optional) TTL for the SPN role credentials.

Type: `number`

Default: `300`

### <a name="input_vault_approle_auth_backend_path"></a> [vault\_approle\_auth\_backend\_path](#input\_vault\_approle\_auth\_backend\_path)

Description: (Optional) Path to enable the Vault AppRole auth backend.

Type: `string`

Default: `"approle"`

### <a name="input_vault_approle_role_name"></a> [vault\_approle\_role\_name](#input\_vault\_approle\_role\_name)

Description: (Optional) Name of the Vault AppRole role.

Type: `string`

Default: `"azure-reader"`

### <a name="input_vault_approle_token_max_ttl"></a> [vault\_approle\_token\_max\_ttl](#input\_vault\_approle\_token\_max\_ttl)

Description: (Optional) Max TTL for the AppRole token (in seconds).

Type: `number`

Default: `7200`

### <a name="input_vault_approle_token_policies"></a> [vault\_approle\_token\_policies](#input\_vault\_approle\_token\_policies)

Description: (Optional) List of policies to attach to the AppRole token.

Type: `list(string)`

Default:

```json
[
  "default"
]
```

### <a name="input_vault_approle_token_ttl"></a> [vault\_approle\_token\_ttl](#input\_vault\_approle\_token\_ttl)

Description: (Optional) TTL for the AppRole token (in seconds).

Type: `number`

Default: `3600`

## Resources

The following resources are used by this module:

- [vault_approle_auth_backend_role.azure_reader](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/approle_auth_backend_role) (resource)
- [vault_auth_backend.approle](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/auth_backend) (resource)
- [vault_azure_secret_backend.azure](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/azure_secret_backend) (resource)
- [vault_azure_secret_backend_role.existing_object_id](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/azure_secret_backend_role) (resource)
- [vault_policy.azure_spn_reader](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/policy) (resource)

## Outputs

The following outputs are exported:

### <a name="output_vault_approle_role_id"></a> [vault\_approle\_role\_id](#output\_vault\_approle\_role\_id)

Description: Role ID for AppRole azure-reader.

<!-- markdownlint-enable -->
<!-- END_TF_DOCS -->
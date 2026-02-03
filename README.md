<!-- BEGIN_TF_DOCS -->

# HCP Vault Azure Secret Engine

This Terraform code provisions and manages the Vault Azure secrets engine, enabling secure dynamic credential generation and automated
root credential rotation for Azure resources. It is designed for secure integration with Azure using a Service Principal (SPN), following
best practices for secret management and automation.

## Permissions

### Vault
- Requires permissions to enable and manage the Azure secrets engine.
- Requires ability to create roles and configure credential rotation.

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
- Securely stores Azure credentials using sensitive Terraform variables
- Automates root credential rotation on a schedule (default: every 24 hours)
- Supports custom roles and policies for fine-grained access control
- Follows best practices for secret management and security

## Prerequisite

### Azure Service Principal (SPN)

An Azure Service Principal (SPN) is required for the Vault Azure secrets engine to securely authenticate and interact with Azure
resources on your behalf. The SPN enables Vault to dynamically generate, rotate, and revoke credentials for applications and users,
ensuring least-privilege access and automated credential lifecycle management. The permissions granted to the SPN determine which Azure
resources Vault can manage and what operations it can perform.

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

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

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

### <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id)

Description: (Required) Azure Subscription ID for Vault Azure secrets engine.

Type: `string`

### <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id)

Description: (Required) Azure Tenant ID for Vault Azure secrets engine.

Type: `string`

## Optional Inputs

No optional inputs.

## Resources

The following resources are used by this module:

- [vault_azure_secret_backend.azure](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/azure_secret_backend) (resource)

## Outputs

No outputs.

<!-- markdownlint-enable -->
<!-- END_TF_DOCS -->
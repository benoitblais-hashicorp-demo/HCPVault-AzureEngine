
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

- **VAULT_TOKEN**: Set the `VAULT_TOKEN` environment variable with a valid Vault token
- **VAULT_ADDR**: Set the `VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **VAULT_NAMESPACE**: Set to `admin` to provision resources in the admin namespace

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
  
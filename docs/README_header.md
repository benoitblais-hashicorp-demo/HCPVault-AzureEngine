
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

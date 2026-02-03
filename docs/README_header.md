
# HCP Vault Azure Secret Engine

This Terraform module provisions and manages the Vault Azure secrets engine with automated root credential rotation, supporting secure
dynamic credential generation and static credential rotation. The module integrates with Azure using a Service Principal (SPN),
following best practices for secret management and automation.

## Permissions

### Vault

- Requires capability to enable and configure the Azure secrets engine (`update`, `create`, `read`, `delete` on `sys/mounts` and `azure/*`).
- Requires ability to create, update, and delete secret backend roles (`create`, `update`, `read`, `delete` on `azure/roles/*`).
- Requires ability to manage credential rotation schedules and policies (`update`, `read` on `azure/*`).
- Requires ability to configure and manage AppRole authentication (`create`, `update`, `read`, `delete` on `auth/approle/*`).
- Requires ability to create and manage Vault policies for least-privilege access (`create`, `update`, `read`, `delete` on `sys/policy/*`).

## Authentication

Authentication to Vault can be configured using one of the following methods:

### Static Token Authentication

Use environment variables to authenticate with a static Vault token:

- **VAULT_TOKEN**: Set the `VAULT_TOKEN` environment variable with a valid Vault token
- **VAULT_ADDR**: Set the `VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **VAULT_NAMESPACE**: Set to `admin` to provision resources in the admin namespace

Example:

```bash
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_TOKEN="your-vault-token"
export VAULT_NAMESPACE="admin"
```

### HCP Terraform Dynamic Credentials (Recommended)

For enhanced security, use HCP Terraform's dynamic provider credentials feature to authenticate to Vault without storing static tokens.
This method uses workload identity (JWT/OIDC) to generate short-lived Vault tokens automatically.

**Benefits:**

- No static credentials stored in Terraform Cloud/Enterprise
- Automatic token rotation with short TTL
- Improved security posture with just-in-time authentication
- Centralized audit trail in both HCP Terraform and Vault

Use environment variables to authenticate with a static Vault token:

- **TFC_VAULT_PROVIDER_AUTH**: Set the `TFC_VAULT_PROVIDER_AUTH` environment variable to `true`.
- **TFC_VAULT_ADDR**: Set the `TFC_VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **TFC_VAULT_NAMESPACE**: Set the `TFC_VAULT_NAMESPACE` environment variable to your Vault namespace (e.g., `admin`)
- **TFC_VAULT_RUN_ROLE**: Set the `TFC_VAULT_RUN_ROLE` environment variable to the JWT role name configured in Vault (e.g., `hcp-terraform`)

**Documentation:**

- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)

## Features

- Enables Vault Azure secrets engine for credential management
- All backend, role, and policy attributes are configurable via variables for maximum flexibility
- Securely stores Azure credentials using sensitive Terraform variables
- Automates root credential rotation on a schedule (default: every 24 hours, configurable)
- Supports both dynamic and static credential roles for different use cases
- Provides optional demo resources with AppRole authentication for testing and demonstration
- Includes ready-to-use demo scripts showing complete credential lifecycle
- Includes automated rotation script for static credentials (cron-compatible)
- Supports custom roles and policies for fine-grained access control

## How to Read Azure Secrets

To read Azure secrets from Vault, first set the required environment variables:

```bash
export VAULT_ADDR=""
export VAULT_NAMESPACE=""
export VAULT_TOKEN=""
```

Then, use the following Vault CLI command to retrieve dynamic Azure credentials:

```bash
vault read azure/creds/<role_name>
```

Replace `<role_name>` with the name of the Azure role you have configured (e.g., `hcpvault-demo-existingobjectid`).

Example:

```bash
vault read azure/creds/hcpvault-demo-existingobjectid
```

This command will return a set of dynamic Azure credentials with the following information:

- `client_id` - Azure Service Principal client ID
- `client_secret` - Azure Service Principal client secret
- `lease_duration` - Credential validity period (default: 5 minutes)
- `lease_renewable` - Whether the lease can be renewed

**Note**: The credentials are temporary and will expire after the lease duration. Request new credentials by running the command again.

## Demo Script

This module includes optional demo scripts that showcase the complete Azure credential lifecycle. When `enable_demo_resources` is set to
`true` (default), the module provisions:

- AppRole authentication backend for machine-to-machine authentication
- Dedicated AppRole roles with least-privilege policies
- Two automated demo scripts demonstrating:
  - AppRole authentication to Vault
  - Credential retrieval from Azure secrets engine
  - Azure CLI authentication using temporary credentials
  - Display of Azure account information
  - Automatic credential lifecycle management

See the [RUN_DEMO.md](./docs/RUN_DEMO.md) file for detailed instructions on running the demonstration.

### Automated Static Credential Rotation

For production environments requiring automated static credential management, this module includes a cron-compatible rotation script
([rotate_static_credentials.sh](../rotate_static_credentials.sh)) that:

- Authenticates using AppRole credentials
- Reads static credentials from Vault (triggering rotation based on rotation_period)
- Logs rotation activity with timestamps for auditing
- Securely handles Vault tokens with automatic revocation
- Provides exit codes for monitoring and alerting

See [ROTATION_SCRIPT.md](./ROTATION_SCRIPT.md) for detailed setup instructions, cron scheduling examples, and production deployment
best practices.

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

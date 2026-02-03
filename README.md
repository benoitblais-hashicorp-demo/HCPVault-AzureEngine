<!-- BEGIN_TF_DOCS -->

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

- **VAULT\_TOKEN**: Set the `VAULT_TOKEN` environment variable with a valid Vault token
- **VAULT\_ADDR**: Set the `VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **VAULT\_NAMESPACE**: Set to `admin` to provision resources in the admin namespace

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

- **TFC\_VAULT\_PROVIDER\_AUTH**: Set the `TFC_VAULT_PROVIDER_AUTH` environment variable to `true`.
- **TFC\_VAULT\_ADDR**: Set the `TFC_VAULT_ADDR` environment variable to your Vault server address (e.g., `https://vault.example.com:8200`)
- **TFC\_VAULT\_NAMESPACE**: Set the `TFC_VAULT_NAMESPACE` environment variable to your Vault namespace (e.g., `admin`)
- **TFC\_VAULT\_RUN\_ROLE**: Set the `TFC_VAULT_RUN_ROLE` environment variable to the JWT role name configured in Vault (e.g., `hcp-terraform`)

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

See the [RUN\_DEMO.md](./docs/RUN\_DEMO.md) file for detailed instructions on running the demonstration.

### Automated Static Credential Rotation

For production environments requiring automated static credential management, this module includes a cron-compatible rotation script
([rotate\_static\_credentials.sh](../rotate\_static\_credentials.sh)) that:

- Authenticates using AppRole credentials
- Reads static credentials from Vault (triggering rotation based on rotation\_period)
- Logs rotation activity with timestamps for auditing
- Securely handles Vault tokens with automatic revocation
- Provides exit codes for monitoring and alerting

See [ROTATION\_SCRIPT.md](./ROTATION\_SCRIPT.md) for detailed setup instructions, cron scheduling examples, and production deployment
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

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (5.6.0)

## Modules

No modules.

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_approle_backend_path"></a> [approle\_backend\_path](#input\_approle\_backend\_path)

Description: (Optional) Path where AppRole auth backend is mounted in Vault.

Type: `string`

Default: `"approle"`

### <a name="input_azure_client_id"></a> [azure\_client\_id](#input\_azure\_client\_id)

Description: (Optional) Azure Client ID for Vault Azure secrets engine. If provided, `azure_client_secret`, `azure_subscription_id`, and `azure_tenant_id` must also be provided.

Type: `string`

Default: `""`

### <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret)

Description: (Optional if azure\_client\_id is provided) Azure Client Secret for Vault Azure secrets engine.

Type: `string`

Default: `""`

### <a name="input_azure_dynamic_spn_max_ttl"></a> [azure\_dynamic\_spn\_max\_ttl](#input\_azure\_dynamic\_spn\_max\_ttl)

Description: (Optional) Max TTL for the SPN role for dynamic credentials. Default is 600 seconds.

Type: `number`

Default: `600`

### <a name="input_azure_dynamic_spn_object_id"></a> [azure\_dynamic\_spn\_object\_id](#input\_azure\_dynamic\_spn\_object\_id)

Description: (Optional) Azure AD Application Object ID for the SPN role with dynamic credentials.

Type: `string`

Default: `""`

### <a name="input_azure_dynamic_spn_role_name"></a> [azure\_dynamic\_spn\_role\_name](#input\_azure\_dynamic\_spn\_role\_name)

Description: (Optional) Name of the Azure SPN role for Vault for dynamic credentials.

Type: `string`

Default: `"HCPVault-Demo-Dynamic"`

### <a name="input_azure_dynamic_spn_ttl"></a> [azure\_dynamic\_spn\_ttl](#input\_azure\_dynamic\_spn\_ttl)

Description: (Optional) TTL for the SPN role for dynamic credentials. Default is 300 seconds.

Type: `number`

Default: `300`

### <a name="input_azure_identity_token_ttl"></a> [azure\_identity\_token\_ttl](#input\_azure\_identity\_token\_ttl)

Description: (Optional) TTL for identity tokens issued by the backend (in seconds). Default is 3600 seconds.

Type: `number`

Default: `3600`

### <a name="input_azure_rotation_schedule"></a> [azure\_rotation\_schedule](#input\_azure\_rotation\_schedule)

Description: (Optional) Cron schedule for root credential rotation. Default is "0 */24 * * *".

Type: `string`

Default: `"0 */24 * * *"`

### <a name="input_azure_rotation_window"></a> [azure\_rotation\_window](#input\_azure\_rotation\_window)

Description: (Optional) Window for root credential rotation (in seconds). Default is 3600 seconds.

Type: `number`

Default: `3600`

### <a name="input_azure_secret_backend_path"></a> [azure\_secret\_backend\_path](#input\_azure\_secret\_backend\_path)

Description: (Optional) Path to enable the Azure secrets engine in Vault.

Type: `string`

Default: `"azure"`

### <a name="input_azure_static_spn_object_id"></a> [azure\_static\_spn\_object\_id](#input\_azure\_static\_spn\_object\_id)

Description: (Optional) Azure AD Application Object ID for the SPN role with static credentials.

Type: `string`

Default: `""`

### <a name="input_azure_static_spn_role_name"></a> [azure\_static\_spn\_role\_name](#input\_azure\_static\_spn\_role\_name)

Description: (Optional) Name of the Azure SPN role for Vault for static credentials.

Type: `string`

Default: `"HCPVault-Demo-Static"`

### <a name="input_azure_static_spn_ttl"></a> [azure\_static\_spn\_ttl](#input\_azure\_static\_spn\_ttl)

Description: (Optional) TTL for the SPN role for static credentials. Default is 1 year (31536000 seconds).

Type: `number`

Default: `31536000`

### <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id)

Description: (Optional if azure\_client\_id is provided) Azure Subscription ID for Vault Azure secrets engine.

Type: `string`

Default: `""`

### <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id)

Description: (Optional if azure\_client\_id is provided) Azure Tenant ID for Vault Azure secrets engine.

Type: `string`

Default: `""`

### <a name="input_demo_script_dynamic_approle_name"></a> [demo\_script\_dynamic\_approle\_name](#input\_demo\_script\_dynamic\_approle\_name)

Description: (Optional) Name of the AppRole for the dynamic credentials demo script.

Type: `string`

Default: `"azure-demo-script-dynamic"`

### <a name="input_demo_script_dynamic_policy_name"></a> [demo\_script\_dynamic\_policy\_name](#input\_demo\_script\_dynamic\_policy\_name)

Description: (Optional) Name of the policy for the dynamic credentials demo script.

Type: `string`

Default: `"azure-demo-script-dynamic-policy"`

### <a name="input_demo_script_secret_id_ttl"></a> [demo\_script\_secret\_id\_ttl](#input\_demo\_script\_secret\_id\_ttl)

Description: (Optional) TTL for AppRole Secret ID in seconds. Default is 0 (no expiration).

Type: `number`

Default: `0`

### <a name="input_demo_script_static_approle_name"></a> [demo\_script\_static\_approle\_name](#input\_demo\_script\_static\_approle\_name)

Description: (Optional) Name of the AppRole for the static credentials demo script.

Type: `string`

Default: `"azure-demo-script-static"`

### <a name="input_demo_script_static_policy_name"></a> [demo\_script\_static\_policy\_name](#input\_demo\_script\_static\_policy\_name)

Description: (Optional) Name of the policy for the static credentials demo script.

Type: `string`

Default: `"azure-demo-script-static-policy"`

### <a name="input_demo_script_token_max_ttl"></a> [demo\_script\_token\_max\_ttl](#input\_demo\_script\_token\_max\_ttl)

Description: (Optional) Maximum TTL for tokens issued to the demo script in seconds. Default is 3600 (1 hour).

Type: `number`

Default: `3600`

### <a name="input_demo_script_token_ttl"></a> [demo\_script\_token\_ttl](#input\_demo\_script\_token\_ttl)

Description: (Optional) TTL for tokens issued to the demo script in seconds. Default is 1800 (30 minutes).

Type: `number`

Default: `1800`

### <a name="input_enable_demo_resources"></a> [enable\_demo\_resources](#input\_enable\_demo\_resources)

Description: (Optional) Enable creation of demo script resources (AppRole backend, role, and policy). Default is true.

Type: `bool`

Default: `true`

## Resources

The following resources are used by this module:

- [vault_approle_auth_backend_role.demo_script_dynamic](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/approle_auth_backend_role) (resource)
- [vault_approle_auth_backend_role.demo_script_static](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/approle_auth_backend_role) (resource)
- [vault_auth_backend.approle](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/auth_backend) (resource)
- [vault_azure_secret_backend.this](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/azure_secret_backend) (resource)
- [vault_azure_secret_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/azure_secret_backend_role) (resource)
- [vault_azure_secret_backend_static_role.static_role](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/azure_secret_backend_static_role) (resource)
- [vault_policy.demo_script_dynamic](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/policy) (resource)
- [vault_policy.demo_script_static](https://registry.terraform.io/providers/hashicorp/vault/5.6.0/docs/resources/policy) (resource)

## Outputs

The following outputs are exported:

### <a name="output_azure_dynamic_role_name"></a> [azure\_dynamic\_role\_name](#output\_azure\_dynamic\_role\_name)

Description: Name of the Azure dynamic credentials role.

### <a name="output_azure_static_role_name"></a> [azure\_static\_role\_name](#output\_azure\_static\_role\_name)

Description: Name of the Azure static credentials role.

### <a name="output_demo_script_dynamic_approle_name"></a> [demo\_script\_dynamic\_approle\_name](#output\_demo\_script\_dynamic\_approle\_name)

Description: Name of the AppRole for the dynamic credentials demo script.

### <a name="output_demo_script_dynamic_role_id"></a> [demo\_script\_dynamic\_role\_id](#output\_demo\_script\_dynamic\_role\_id)

Description: AppRole Role ID for the dynamic credentials demo script. Use this with Secret ID to authenticate.

### <a name="output_demo_script_static_approle_name"></a> [demo\_script\_static\_approle\_name](#output\_demo\_script\_static\_approle\_name)

Description: Name of the AppRole for the static credentials demo script.

### <a name="output_demo_script_static_role_id"></a> [demo\_script\_static\_role\_id](#output\_demo\_script\_static\_role\_id)

Description: AppRole Role ID for the static credentials demo script. Use this with Secret ID to authenticate.

<!-- markdownlint-enable -->
<!-- END_TF_DOCS -->
# Azure Secret Engine Demo

This demonstration showcases the complete lifecycle of HashiCorp Vault's Azure Secrets Engine with **two separate demos**:

1. **Dynamic Credentials Demo** - Short-lived credentials (5 minutes) generated on-demand
2. **Static Credentials Demo** - Long-lived credentials (1 year) automatically rotated by Vault

Both demos illustrate secure credential retrieval using AppRole authentication, least-privilege access control, and demonstrate that each
AppRole can only access its designated credential type. This highlights the elimination of long-lived static secrets in application code,
automated credential rotation, and centralized access control.

## What This Demo Demonstrates

This demo illustrates the following key integration points:

### 1. **AppRole Authentication (Machine-to-Machine)**

- Applications authenticate to Vault using AppRole with Role ID and Secret ID
- No need for human interaction or user credentials
- Token-based authentication with configurable TTL (default: 30 minutes)
- Policies enforce least-privilege access to specific Azure credential paths

### 2. **Dynamic Credential Generation**

- Vault generates temporary Azure Service Principal credentials on-demand
- Credentials are created with a short TTL (default: 5 minutes)
- Each credential request creates unique, isolated credentials
- Automatic credential revocation after lease expiration

### 3. **Azure Resource Access**

- Applications use temporary credentials to authenticate to Azure CLI
- Full Azure API access based on Service Principal permissions
- Demonstrates querying Azure resources (account info, subscriptions, resource groups)
- Credentials automatically expire, requiring no manual cleanup

### 4. **Security Best Practices**

- Zero long-lived credentials stored in application configuration
- Centralized credential lifecycle management through Vault
- Complete audit trail of credential access in Vault logs
- Reduced blast radius if credentials are compromised (short TTL)
- **Least-privilege access control**: Each AppRole can only read its designated credential type
- **Policy enforcement demonstration**: Scripts test cross-access and fail as expected

## Demo Components

1. **Terraform Configuration Files**

   Provisions HCP Vault resources including Azure secrets engine, dynamic and static credential roles, AppRole authentication backend,
   and least-privilege policies. Created when variable `enable_demo_resources` is set to `true`.

1. **Demo Scripts**

   Two Bash scripts demonstrate credential retrieval and usage: `scripts/demo_azure_dynamic_credentials.sh` for short-lived credentials and
   `scripts/demo_azure_static_credentials.sh` for long-lived credentials. Both scripts include least-privilege testing.

1. **Required Variables**

   Core variables: `azure_client_id`, `azure_client_secret`, `azure_subscription_id`, `azure_tenant_id`. Azure AD Application Object
   IDs: `azure_dynamic_spn_object_id` and `azure_static_spn_object_id` must be configured for the respective credential roles.

## Prerequisites

Before running the demo, ensure you have the following:

1. **Azure CLI Installed** - Required for authenticating to Azure with generated credentials
   - Download from: <https://learn.microsoft.com/en-us/cli/azure/install-azure-cli>
   - On Windows, after installation, you may need to add to PATH: `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin`
   - Verify installation: `az version`

2. **Vault CLI Installed** - Required for generating Secret IDs
   - Download from: <https://developer.hashicorp.com/vault/install>
   - Verify installation: `vault version`

3. **Terraform Outputs** - Retrieve Role IDs after Terraform deployment
   - `terraform output demo_script_dynamic_role_id`
   - `terraform output demo_script_static_role_id`

4. **Azure Tenant ID** - Your Azure Active Directory tenant ID
   - Find in Azure Portal → Azure Active Directory → Overview

**Important Note:** The demo service principals authenticate successfully to Azure but may show "No subscriptions found" if no Azure RBAC roles are assigned. This is expected behavior - it demonstrates that Vault is generating valid Azure credentials. For production use, assign appropriate Azure roles (Reader, Contributor, etc.) to give the service principals actual permissions.

## How Module Lifecycle Works in This Demo

This demo uses AppRole authentication in Vault to enable secure machine-to-machine authentication. Two separate AppRole roles are
configured with least-privilege policies, ensuring each role can only access its designated Azure credential type. The dynamic
credentials AppRole can only read short-lived credentials, while the static credentials AppRole can only read long-lived credentials.
Applications authenticate using a Role ID and dynamically generated Secret ID to obtain a Vault token. The two demo scripts demonstrate
this least-privilege enforcement by attempting to read each other's credentials, which fails as expected, proving that proper access
control is enforced at the Vault policy level.

### The Workflow

1. **Retrieve Demo Credentials**

   Before running the demo scripts, you must retrieve the AppRole credentials that applications will use to authenticate to Vault. The
   Role ID (static identifier) is obtained from Terraform outputs, while the Secret ID (dynamic, short-lived credential) must be
   generated on-demand using the Vault CLI. These two pieces together form the AppRole authentication credentials required by the demo
   scripts.

   ```bash
   # Set Vault environment variables
   export VAULT_ADDR="https://your-vault.example.com:8200"
   export VAULT_NAMESPACE="azureengine-demo"  # Or your custom namespace_path value
   export VAULT_TOKEN="your-vault-token"

   # Get Role IDs from Terraform output
   terraform output demo_script_dynamic_role_id  # For dynamic demo
   terraform output demo_script_static_role_id   # For static demo

   # Generate Secret ID for dynamic demo
   vault write -f auth/approle/role/azure-demo-script-dynamic/secret-id

   # Generate Secret ID for static demo
   vault write -f auth/approle/role/azure-demo-script-static/secret-id
   ```

   **Expected Output:**

   ```text
   Key                   Value
   ---                   -----
   secret_id             987fcdeb-51a2-a268-8f25-2ead583453fe
   secret_id_accessor    b4405d83-a973-f9de-6773-5e3e6e12e4e8
   secret_id_num_uses    0
   secret_id_ttl         0s
   ```

2. **Set Environment Variables for Demo Scripts**

   The demo scripts require environment variables to configure Vault connection details and authentication credentials. Each demo uses
   unique variable names to allow running both demos independently without conflicts.

   **For Dynamic Demo:**

   ```bash
   export VAULT_ADDR="https://your-vault.example.com:8200"
   export VAULT_NAMESPACE="azureengine-demo"  # Or your custom namespace_path value
   export VAULT_DYNAMIC_ROLE_ID="demo_script_dynamic_role_id-from-terraform-output"
   export VAULT_DYNAMIC_SECRET_ID="dynamic-secret-id-from-step-1"
   export AZURE_TENANT_ID="your-azure-tenant-id"
   ```

   **For Static Demo:**

   ```bash
   export VAULT_ADDR="https://your-vault.example.com:8200"
   export VAULT_NAMESPACE="azureengine-demo"  # Or your custom namespace_path value
   export VAULT_STATIC_ROLE_ID="demo_script_static_role_id-from-terraform-output"
   export VAULT_STATIC_SECRET_ID="static-secret-id-from-step-1"
   export AZURE_TENANT_ID="your-azure-tenant-id"
   ```

3. **Run the Demo Scripts**

   The scripts authenticate to Vault using AppRole, retrieve Azure credentials, authenticate to Azure CLI, display account information,
   and demonstrate least-privilege enforcement by attempting cross-access (which fails as expected).

   **Run Dynamic Demo:**

   ```bash
   chmod +x scripts/demo_azure_dynamic_credentials.sh
   ./scripts/demo_azure_dynamic_credentials.sh
   ```

   **Run Static Demo:**

   ```bash
   chmod +x scripts/demo_azure_static_credentials.sh
   ./scripts/demo_azure_static_credentials.sh
   ```

## Demo Value Proposition

### For Security Teams

✅ **Eliminated Static Credentials**

- No Azure credentials stored in environment variables, config files, or code
- Reduces risk of credential leakage in Git repositories or log files

✅ **Centralized Access Control**

- All credential access governed by Vault policies
- Single point of audit and access revocation
- Policy changes take effect immediately without application redeployment

✅ **Automatic Credential Rotation**

- Credentials rotate automatically based on TTL
- Root credentials rotated on schedule (default: daily)
- No manual password management or rotation scripts

✅ **Reduced Blast Radius**

- Compromised credentials expire within minutes
- Each application instance gets unique credentials
- Revocation is instant and doesn't affect other applications

### For Development Teams

✅ **Simplified Credential Management**

- No need to distribute, rotate, or store Azure credentials
- Applications request credentials on-demand using AppRole
- Standard Vault API for all secret access

✅ **Environment Parity**

- Same authentication flow works across dev, staging, production
- Different AppRole roles for different environments
- No hardcoded credentials in deployment pipelines

✅ **Self-Service Credential Access**

- Developers can test with temporary credentials locally
- No need to request long-lived credentials from security team
- Credentials expire automatically after testing

### For Compliance Teams

✅ **Complete Audit Trail**

- Every credential request logged in Vault audit logs
- Tracks: who, what, when, from where
- Immutable audit logs for compliance reporting

✅ **Least-Privilege Access**

- Applications only access specific Azure roles via policy
- Cannot read other secrets or modify Vault configuration
- Policy enforcement at the Vault level

✅ **Credential Lifecycle Visibility**

- Track credential creation, renewal, and revocation
- Monitoring and alerting on credential access patterns
- Detect anomalous access attempts

## Additional Resources

- [Vault Azure Secrets Engine Documentation](https://developer.hashicorp.com/vault/docs/secrets/azure)
- [Vault AppRole Authentication Documentation](https://developer.hashicorp.com/vault/docs/auth/approle)
- [Azure Service Principal Documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [Best Practices for Vault](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)

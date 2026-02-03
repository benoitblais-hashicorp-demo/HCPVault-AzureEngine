# Static Credentials Rotation Script

This script automates the periodic reading of static Azure credentials from Vault, which triggers Vault's automatic rotation mechanism when the TTL expires. It's designed to be run via cron or other scheduling systems.

## Overview

The `rotate_static_credentials.sh` script performs the following actions:

1. **Authenticates to Vault** using AppRole (Role ID + Secret ID)
2. **Reads static Azure credentials** from Vault (triggers rotation if TTL expired)
3. **Logs credential information** including last rotation time
4. **Verifies role configuration** (optional)
5. **Revokes the Vault token** to maintain security hygiene
6. **Exits with appropriate status codes** for monitoring

## Prerequisites

- Vault CLI installed and in PATH
- `jq` installed for JSON parsing
- AppRole authentication configured in Vault
- Static Azure credentials role configured in Vault

## Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `VAULT_ADDR` | Vault server address | `https://vault.example.com:8200` |
| `VAULT_NAMESPACE` | Vault namespace | `admin` |
| `VAULT_STATIC_ROLE_ID` | AppRole Role ID for static credentials | `7bd975eb-f3f4-fa7f-8926-6d5088439ce0` |
| `VAULT_STATIC_SECRET_ID` | AppRole Secret ID for static credentials | Generated via `vault write -f auth/approle/role/.../secret-id` |
| `VAULT_STATIC_ROLE_NAME` | Azure static credentials role name (optional) | `HCPVault-Demo-Static` (default) |

## Usage

### Manual Execution

```bash
# Set environment variables
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_NAMESPACE="admin"
export VAULT_STATIC_ROLE_ID="your-role-id"
export VAULT_STATIC_SECRET_ID="your-secret-id"
export VAULT_STATIC_ROLE_NAME="HCPVault-Demo-Static"  # Optional

# Run the script
./rotate_static_credentials.sh
```

### Automated Execution with Cron

#### Option 1: Using Environment File

Create an environment file `/etc/vault/rotation.env`:

```bash
VAULT_ADDR=https://vault.example.com:8200
VAULT_NAMESPACE=admin
VAULT_STATIC_ROLE_ID=7bd975eb-f3f4-fa7f-8926-6d5088439ce0
VAULT_STATIC_SECRET_ID=your-secret-id
VAULT_STATIC_ROLE_NAME=HCPVault-Demo-Static
```

Create a wrapper script `/usr/local/bin/vault-rotation-wrapper.sh`:

```bash
#!/bin/bash
source /etc/vault/rotation.env
/path/to/rotate_static_credentials.sh
```

Add to crontab:

```cron
# Run daily at 2 AM
0 2 * * * /usr/local/bin/vault-rotation-wrapper.sh >> /var/log/vault-rotation.log 2>&1

# Run every 12 hours
0 */12 * * * /usr/local/bin/vault-rotation-wrapper.sh >> /var/log/vault-rotation.log 2>&1

# Run weekly on Sunday at 3 AM
0 3 * * 0 /usr/local/bin/vault-rotation-wrapper.sh >> /var/log/vault-rotation.log 2>&1
```

#### Option 2: Direct Cron Entry

```cron
# Run daily at 2 AM with environment variables
0 2 * * * VAULT_ADDR=https://vault.example.com:8200 VAULT_NAMESPACE=admin VAULT_STATIC_ROLE_ID=xxx VAULT_STATIC_SECRET_ID=xxx /path/to/rotate_static_credentials.sh >> /var/log/vault-rotation.log 2>&1
```

**⚠️ Security Warning:** Storing credentials in crontab is not recommended. Use the environment file approach with proper file permissions (600 or 400).

## Scheduling Recommendations

### Based on TTL Configuration

- **1 year TTL**: Run daily or weekly
- **90 days TTL**: Run daily
- **30 days TTL**: Run every 12 hours
- **7 days TTL**: Run every 6 hours

### General Guidelines

1. **Run more frequently than the TTL** to ensure credentials are always fresh
2. **Avoid running too frequently** to reduce Vault API load (minimum: every 1 hour)
3. **Stagger multiple scripts** if rotating multiple credential sets
4. **Monitor logs** for rotation failures

## Monitoring and Alerting

### Exit Codes

- `0`: Success - credentials read and rotation check completed
- `1`: Failure - authentication failed, credential read failed, or other error

### Log Analysis

Monitor logs for:

```bash
# Check for successful rotations
grep "completed successfully" /var/log/vault-rotation.log

# Check for errors
grep "ERROR" /var/log/vault-rotation.log

# Check last rotation time
tail -100 /var/log/vault-rotation.log | grep "Last Rotation"

# Check credentials age
tail -100 /var/log/vault-rotation.log | grep "Credentials age"
```

### Alerting Examples

#### Nagios/Icinga Check

```bash
#!/bin/bash
LAST_SUCCESS=$(grep "completed successfully" /var/log/vault-rotation.log | tail -1)
if [ -z "$LAST_SUCCESS" ]; then
    echo "CRITICAL: No successful rotation found"
    exit 2
fi

LAST_TIME=$(echo "$LAST_SUCCESS" | grep -oP '\[\K[^]]+')
SECONDS_AGO=$(( $(date +%s) - $(date -d "$LAST_TIME" +%s) ))

if [ $SECONDS_AGO -gt 86400 ]; then
    echo "CRITICAL: Last rotation was $((SECONDS_AGO/3600)) hours ago"
    exit 2
elif [ $SECONDS_AGO -gt 43200 ]; then
    echo "WARNING: Last rotation was $((SECONDS_AGO/3600)) hours ago"
    exit 1
else
    echo "OK: Last rotation was $((SECONDS_AGO/60)) minutes ago"
    exit 0
fi
```

#### Prometheus Metrics

Parse logs and expose metrics:

```bash
# vault_rotation_last_success_timestamp
# vault_rotation_errors_total
# vault_rotation_duration_seconds
```

## Troubleshooting

### Authentication Failures

**Error:** `Failed to authenticate to Vault`

**Solutions:**
- Verify VAULT_ADDR is correct and accessible
- Check VAULT_STATIC_ROLE_ID is valid
- Generate a new Secret ID: `vault write -f auth/approle/role/azure-demo-script-static/secret-id`
- Verify AppRole has correct policies attached

### Permission Errors

**Error:** `permission denied` when reading credentials

**Solutions:**
- Check the AppRole policy includes `azure/static-creds/<role-name>`
- Verify the role name matches the configured Azure role in Vault
- Check Vault namespace is correct

### Network Issues

**Error:** Connection timeouts or network errors

**Solutions:**
- Verify network connectivity to Vault
- Check firewall rules
- Verify TLS certificates if using HTTPS
- Test with `curl -v $VAULT_ADDR/v1/sys/health`

## Security Best Practices

1. **Protect Environment Files**
   ```bash
   chmod 600 /etc/vault/rotation.env
   chown root:root /etc/vault/rotation.env
   ```

2. **Use Dedicated AppRole**
   - Create a separate AppRole specifically for rotation
   - Limit policies to only read static credentials
   - Set appropriate Secret ID TTL

3. **Rotate Secret IDs Regularly**
   - Generate new Secret IDs periodically
   - Update environment files/secrets management systems

4. **Monitor and Alert**
   - Set up alerts for script failures
   - Monitor Vault audit logs for suspicious activity
   - Track credential age and rotation frequency

5. **Log Management**
   - Rotate logs regularly
   - Ensure logs don't contain sensitive data
   - Restrict log file permissions (640 or 600)

## Example Output

```
[2026-02-03 10:56:32] Starting static credentials rotation check
[2026-02-03 10:56:32] Vault Address: https://vault.example.com:8200
[2026-02-03 10:56:32] Vault Namespace: admin
[2026-02-03 10:56:32] Role Name: HCPVault-Demo-Static
[2026-02-03 10:56:32] Authenticating to Vault using AppRole...
[2026-02-03 10:56:32] Successfully authenticated to Vault
[2026-02-03 10:56:32] Reading static Azure credentials...
[2026-02-03 10:56:32] Successfully retrieved static credentials
[2026-02-03 10:56:32]   Client ID: 17afc306-8afc-4487-a7a7-59ffcfcb81ee
[2026-02-03 10:56:32]   Last Rotation: 2026-02-03T15:32:13.042966077Z
[2026-02-03 10:56:32]   TTL: N/A
[2026-02-03 10:56:32]   Rotation Period: N/A
[2026-02-03 10:56:32] Credentials were recently rotated (24 minutes ago)
[2026-02-03 10:56:32] Verifying static credentials configuration in Vault...
[2026-02-03 10:56:32] Role configuration:
[2026-02-03 10:56:32]   Application Object ID: f956b276-31c0-42a0-beb3-570347d58d6b
[2026-02-03 10:56:32]   Configured TTL: 31536000s
[2026-02-03 10:56:32]   Rotation Period: 86400
[2026-02-03 10:56:32] Revoking Vault token...
[2026-02-03 10:56:32] Successfully revoked Vault token
[2026-02-03 10:56:32] Static credentials rotation check completed successfully
```

## Integration with CI/CD

### GitLab CI

```yaml
rotate_credentials:
  stage: maintenance
  image: hashicorp/vault:latest
  before_script:
    - apk add --no-cache jq
  script:
    - chmod +x rotate_static_credentials.sh
    - ./rotate_static_credentials.sh
  variables:
    VAULT_ADDR: $VAULT_ADDR
    VAULT_NAMESPACE: $VAULT_NAMESPACE
    VAULT_STATIC_ROLE_ID: $VAULT_STATIC_ROLE_ID
    VAULT_STATIC_SECRET_ID: $VAULT_STATIC_SECRET_ID
  only:
    - schedules
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        VAULT_ADDR = credentials('vault-addr')
        VAULT_NAMESPACE = 'admin'
        VAULT_STATIC_ROLE_ID = credentials('vault-static-role-id')
        VAULT_STATIC_SECRET_ID = credentials('vault-static-secret-id')
    }
    
    triggers {
        cron('0 2 * * *')  // Daily at 2 AM
    }
    
    stages {
        stage('Rotate Credentials') {
            steps {
                sh './rotate_static_credentials.sh'
            }
        }
    }
    
    post {
        failure {
            mail to: 'ops@example.com',
                 subject: "Vault Credential Rotation Failed",
                 body: "Check ${env.BUILD_URL} for details"
        }
    }
}
```

## Additional Resources

- [Vault Azure Secrets Engine Documentation](https://developer.hashicorp.com/vault/docs/secrets/azure)
- [Vault AppRole Authentication](https://developer.hashicorp.com/vault/docs/auth/approle)
- [Cron Expression Generator](https://crontab.guru/)
- [Vault Production Hardening](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)

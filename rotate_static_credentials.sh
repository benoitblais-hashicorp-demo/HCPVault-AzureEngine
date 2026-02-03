#!/bin/bash

# Static Credentials Rotation Script
# This script can be run via cron to periodically read static credentials from Vault,
# triggering Vault's automatic rotation mechanism when the TTL expires.
#
# Usage:
#   ./rotate_static_credentials.sh
#
# Cron Example (run daily at 2 AM):
#   0 2 * * * /path/to/rotate_static_credentials.sh >> /var/log/vault-rotation.log 2>&1
#
# Required Environment Variables:
#   VAULT_ADDR              - Vault server address
#   VAULT_NAMESPACE         - Vault namespace
#   VAULT_STATIC_ROLE_ID    - AppRole Role ID for static credentials
#   VAULT_STATIC_SECRET_ID  - AppRole Secret ID for static credentials
#   VAULT_STATIC_ROLE_NAME  - Azure static credentials role name (optional, default: HCPVault-Demo-Static)

set -e

# Configuration
VAULT_STATIC_ROLE_NAME="${VAULT_STATIC_ROLE_NAME:-HCPVault-Demo-Static}"
APPROLE_PATH="${APPROLE_PATH:-approle}"
LOG_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo "[${LOG_TIMESTAMP}] $1"
}

log_error() {
    echo "[${LOG_TIMESTAMP}] ERROR: $1" >&2
}

# Validate required environment variables
if [ -z "$VAULT_ADDR" ]; then
    log_error "VAULT_ADDR environment variable not set"
    exit 1
fi

if [ -z "$VAULT_NAMESPACE" ]; then
    log_error "VAULT_NAMESPACE environment variable not set"
    exit 1
fi

if [ -z "$VAULT_STATIC_ROLE_ID" ]; then
    log_error "VAULT_STATIC_ROLE_ID environment variable not set"
    exit 1
fi

if [ -z "$VAULT_STATIC_SECRET_ID" ]; then
    log_error "VAULT_STATIC_SECRET_ID environment variable not set"
    exit 1
fi

log "Starting static credentials rotation check"
log "Vault Address: ${VAULT_ADDR}"
log "Vault Namespace: ${VAULT_NAMESPACE}"
log "Role Name: ${VAULT_STATIC_ROLE_NAME}"

# Step 1: Authenticate to Vault using AppRole
log "Authenticating to Vault using AppRole..."

AUTH_RESPONSE=$(vault write -format=json auth/${APPROLE_PATH}/login \
    role_id="${VAULT_STATIC_ROLE_ID}" \
    secret_id="${VAULT_STATIC_SECRET_ID}" 2>&1)

if [ $? -ne 0 ]; then
    log_error "Failed to authenticate to Vault"
    log_error "${AUTH_RESPONSE}"
    exit 1
fi

# Extract token from response
VAULT_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.auth.client_token')

if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" = "null" ]; then
    log_error "Failed to extract Vault token from authentication response"
    exit 1
fi

export VAULT_TOKEN

log "Successfully authenticated to Vault"

# Step 2: Read static credentials (triggers rotation if TTL expired)
log "Reading static Azure credentials..."

CREDS_RESPONSE=$(vault read -format=json azure/static-creds/${VAULT_STATIC_ROLE_NAME} 2>&1)
READ_EXIT_CODE=$?

if [ $READ_EXIT_CODE -ne 0 ]; then
    log_error "Failed to read static credentials"
    log_error "${CREDS_RESPONSE}"
    
    # Revoke token before exit
    vault token revoke -self >/dev/null 2>&1 || true
    exit 1
fi

# Extract credential information
CLIENT_ID=$(echo $CREDS_RESPONSE | jq -r '.data.client_id')
LAST_VAULT_ROTATION=$(echo $CREDS_RESPONSE | jq -r '.data.last_vault_rotation // "N/A"')
TTL=$(echo $CREDS_RESPONSE | jq -r '.data.ttl // "N/A"')
ROTATION_PERIOD=$(echo $CREDS_RESPONSE | jq -r '.data.rotation_period // "N/A"')

log "Successfully retrieved static credentials"
log "  Client ID: ${CLIENT_ID}"
log "  Last Rotation: ${LAST_VAULT_ROTATION}"
log "  TTL: ${TTL}"
log "  Rotation Period: ${ROTATION_PERIOD}"

# Step 3: Check if credentials were recently rotated
if [ "$LAST_VAULT_ROTATION" != "N/A" ]; then
    ROTATION_TIMESTAMP=$(date -d "$LAST_VAULT_ROTATION" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$LAST_VAULT_ROTATION" +%s 2>/dev/null || echo "0")
    CURRENT_TIMESTAMP=$(date +%s)
    TIME_SINCE_ROTATION=$((CURRENT_TIMESTAMP - ROTATION_TIMESTAMP))
    
    if [ $TIME_SINCE_ROTATION -lt 3600 ]; then
        log "Credentials were recently rotated ($(($TIME_SINCE_ROTATION / 60)) minutes ago)"
    else
        log "Credentials age: $(($TIME_SINCE_ROTATION / 3600)) hours"
    fi
fi

# Step 4: Verify credentials are valid by attempting to list Azure roles
log "Verifying static credentials configuration in Vault..."

set +e  # Temporarily disable exit on error
ROLE_INFO=$(vault read -format=json azure/static-roles/${VAULT_STATIC_ROLE_NAME} 2>&1)
ROLE_READ_EXIT=$?
set -e  # Re-enable exit on error

if [ $ROLE_READ_EXIT -eq 0 ]; then
    APP_OBJECT_ID=$(echo $ROLE_INFO | jq -r '.data.application_object_id // "N/A"')
    TTL_CONFIG=$(echo $ROLE_INFO | jq -r '.data.ttl // "N/A"')
    ROTATION_PERIOD_CONFIG=$(echo $ROLE_INFO | jq -r '.data.rotation_period // "N/A"')
    
    log "Role configuration:"
    log "  Application Object ID: ${APP_OBJECT_ID}"
    log "  Configured TTL: ${TTL_CONFIG}"
    log "  Rotation Period: ${ROTATION_PERIOD_CONFIG}"
else
    log "Warning: Could not read role configuration details"
fi

# Step 5: Revoke Vault token
log "Revoking Vault token..."
vault token revoke -self >/dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Successfully revoked Vault token"
else
    log "Warning: Failed to revoke Vault token (may have already expired)"
fi

log "Static credentials rotation check completed successfully"
exit 0

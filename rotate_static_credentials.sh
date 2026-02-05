#!/bin/bash

# Static Credentials Rotation Script
# This script forces rotation of static credentials from Vault every time it runs.
# Use this for scheduled/automated rotation via cron or CI/CD pipelines.
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

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
VAULT_STATIC_ROLE_NAME="${VAULT_STATIC_ROLE_NAME:-HCPVault-Demo-Static}"
APPROLE_PATH="${APPROLE_PATH:-approle}"
LOG_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo -e "[${LOG_TIMESTAMP}] $1"
}

log_error() {
    echo -e "${RED}[${LOG_TIMESTAMP}] ERROR: $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[${LOG_TIMESTAMP}] ✓ $1${NC}"
}

log_step() {
    echo -e "${YELLOW}[${LOG_TIMESTAMP}] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[${LOG_TIMESTAMP}] $1${NC}"
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Vault Static Credentials Rotation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
log "Vault Address: ${VAULT_ADDR}"
log "Vault Namespace: ${VAULT_NAMESPACE}"
log "Role Name: ${VAULT_STATIC_ROLE_NAME}"
echo ""

# Step 1: Authenticate to Vault using AppRole
log_step "Step 1: Authenticating to Vault using AppRole..."

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

log_success "Successfully authenticated to Vault"

# TROUBLESHOOTING: Check token details
echo ""
log_info "=== TROUBLESHOOTING: Token Details ==="
TOKEN_INFO=$(vault token lookup -format=json 2>&1)
if [ $? -eq 0 ]; then
    log "  Token Policies: $(echo $TOKEN_INFO | jq -r '.data.policies[]' | tr '\n' ', ')"
    log "  Token TTL: $(echo $TOKEN_INFO | jq -r '.data.ttl') seconds"
    log "  Token Renewable: $(echo $TOKEN_INFO | jq -r '.data.renewable')"
else
    log "  Warning: Could not lookup token details"
fi

# TROUBLESHOOTING: Test permissions on rotation path
log_info "=== TROUBLESHOOTING: Testing Permissions ==="
log "  Testing read access to azure/static-creds/${VAULT_STATIC_ROLE_NAME}..."
TEST_READ=$(vault read -format=json azure/static-creds/${VAULT_STATIC_ROLE_NAME} 2>&1)
if [ $? -eq 0 ]; then
    log_success "  Read access: GRANTED"
else
    echo -e "${RED}  ✗ Read access: DENIED${NC}"
    log "  Error: $TEST_READ"
fi

log "  Testing write access to azure/rotate-role/${VAULT_STATIC_ROLE_NAME}..."
# Just test the path capability, don't actually rotate yet
CAPABILITIES=$(vault token capabilities azure/rotate-role/${VAULT_STATIC_ROLE_NAME} 2>&1)
log "  Capabilities on rotate path: ${CAPABILITIES}"

log_info "=== END TROUBLESHOOTING ==="
echo ""

# Step 2: Read current credentials to capture pre-rotation state
log_step "Step 2: Reading current credentials before rotation..."

BEFORE_CREDS=$(vault read -format=json azure/static-creds/${VAULT_STATIC_ROLE_NAME} 2>&1)
BEFORE_READ_EXIT=$?

if [ $BEFORE_READ_EXIT -ne 0 ]; then
    log "Warning: Could not read credentials before rotation"
    BEFORE_ROTATION=""
    BEFORE_SECRET=""
    SHOULD_ROTATE="yes"
else
    BEFORE_ROTATION=$(echo $BEFORE_CREDS | jq -r '.data.last_vault_rotation // "N/A"')
    BEFORE_SECRET=$(echo $BEFORE_CREDS | jq -r '.data.client_secret // "N/A"')
    BEFORE_SECRET_TRUNCATED="${BEFORE_SECRET:0:8}..."
    log "  Current rotation timestamp: ${BEFORE_ROTATION}"
    log "  Current client secret (truncated): ${BEFORE_SECRET_TRUNCATED}"
    
    # Check if enough time has passed since last rotation (minimum 5 minutes to avoid Azure throttling)
    MIN_ROTATION_INTERVAL=300  # 5 minutes in seconds
    SHOULD_ROTATE="yes"
    
    if [ "$BEFORE_ROTATION" != "N/A" ]; then
        LAST_ROTATION_EPOCH=$(date -d "$BEFORE_ROTATION" +%s 2>/dev/null || echo "0")
        CURRENT_EPOCH=$(date +%s)
        TIME_SINCE_ROTATION=$((CURRENT_EPOCH - LAST_ROTATION_EPOCH))
        
        if [ $TIME_SINCE_ROTATION -lt $MIN_ROTATION_INTERVAL ]; then
            SHOULD_ROTATE="no"
            WAIT_TIME=$((MIN_ROTATION_INTERVAL - TIME_SINCE_ROTATION))
            echo -e "${YELLOW}  ⚠ Last rotation was ${TIME_SINCE_ROTATION} seconds ago${NC}"
            echo -e "${YELLOW}  ⚠ Azure requires at least ${MIN_ROTATION_INTERVAL} seconds between rotations${NC}"
            echo -e "${YELLOW}  ⚠ Please wait ${WAIT_TIME} more seconds before rotating again${NC}"
        else
            log "  Time since last rotation: ${TIME_SINCE_ROTATION} seconds (OK to rotate)"
        fi
    fi
fi
echo ""

# Step 3: Force rotation of static credentials with retry logic
if [ "$SHOULD_ROTATE" = "no" ]; then
    log_step "Step 3: Skipping rotation (too soon since last rotation)"
    echo ""
    
    # Skip to reading current credentials
    log_step "Step 4: Reading current credentials..."
    CREDS_RESPONSE=$(vault read -format=json azure/static-creds/${VAULT_STATIC_ROLE_NAME} 2>&1)
    READ_EXIT_CODE=$?
    
    if [ $READ_EXIT_CODE -ne 0 ]; then
        log_error "Failed to read credentials"
        vault token revoke -self >/dev/null 2>&1 || true
        exit 1
    fi
    
    CLIENT_ID=$(echo $CREDS_RESPONSE | jq -r '.data.client_id')
    AFTER_SECRET=$(echo $CREDS_RESPONSE | jq -r '.data.client_secret // "N/A"')
    AFTER_SECRET_TRUNCATED="${AFTER_SECRET:0:8}..."
    LAST_VAULT_ROTATION=$(echo $CREDS_RESPONSE | jq -r '.data.last_vault_rotation // "N/A"')
    TTL=$(echo $CREDS_RESPONSE | jq -r '.data.ttl // "N/A"')
    ROTATION_PERIOD=$(echo $CREDS_RESPONSE | jq -r '.data.rotation_period // "N/A"')
    
    log "  Client ID: ${CLIENT_ID}"
    log "  Client secret (truncated): ${AFTER_SECRET_TRUNCATED}"
    log "  Last Rotation: ${LAST_VAULT_ROTATION}"
    echo ""
    
    # Skip verification and go to cleanup
    log_step "Step 5: Cleaning up..."
    vault token revoke -self >/dev/null 2>&1
    log_success "Successfully revoked Vault token"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}⚠ No rotation performed (too soon)${NC}"
    echo -e "${BLUE}========================================${NC}"
    exit 0
fi

log_step "Step 3: Forcing rotation of static Azure credentials..."

set +e  # Temporarily disable exit on error for rotation attempts

MAX_RETRIES=3
RETRY_COUNT=0
RETRY_DELAY=5

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    log "  Rotation attempt $((RETRY_COUNT + 1))/${MAX_RETRIES}..."
    ROTATE_RESPONSE=$(vault write -f -format=json azure/rotate-role/${VAULT_STATIC_ROLE_NAME} 2>&1)
    ROTATE_EXIT_CODE=$?
    
    if [ $ROTATE_EXIT_CODE -eq 0 ]; then
        log_success "Successfully rotated static credentials"
        break
    fi
    
    # Check if error is due to Azure throttling
    if echo "$ROTATE_RESPONSE" | grep -q "concurrent requests"; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}  ⚠ Azure throttling detected. Waiting ${RETRY_DELAY} seconds before retry...${NC}"
            sleep $RETRY_DELAY
            RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
            continue  # Go to next iteration
        else
            log_error "Failed to rotate credentials after ${MAX_RETRIES} attempts due to Azure throttling"
            vault token revoke -self >/dev/null 2>&1 || true
            set -e
            exit 1
        fi
    else
        # Different error, don't retry
        log_error "Failed to rotate static credentials (non-throttling error)"
        log "  Error details: ${ROTATE_RESPONSE:0:300}"
        vault token revoke -self >/dev/null 2>&1 || true
        set -e
        exit 1
    fi
done

if [ $ROTATE_EXIT_CODE -ne 0 ]; then
    log_error "Rotation failed after all retries"
    vault token revoke -self >/dev/null 2>&1 || true
    set -e
    exit 1
fi

set -e  # Re-enable exit on error
echo ""

# Step 4: Read the newly rotated credentials
log_step "Step 4: Reading rotated credentials..."

CREDS_RESPONSE=$(vault read -format=json azure/static-creds/${VAULT_STATIC_ROLE_NAME} 2>&1)
READ_EXIT_CODE=$?

if [ $READ_EXIT_CODE -ne 0 ]; then
    log_error "Failed to read rotated credentials"
    log_error "${CREDS_RESPONSE}"
    
    # Revoke token before exit
    vault token revoke -self >/dev/null 2>&1 || true
    exit 1
fi

# Extract credential information
CLIENT_ID=$(echo $CREDS_RESPONSE | jq -r '.data.client_id')
AFTER_SECRET=$(echo $CREDS_RESPONSE | jq -r '.data.client_secret // "N/A"')
AFTER_SECRET_TRUNCATED="${AFTER_SECRET:0:8}..."
LAST_VAULT_ROTATION=$(echo $CREDS_RESPONSE | jq -r '.data.last_vault_rotation // "N/A"')
TTL=$(echo $CREDS_RESPONSE | jq -r '.data.ttl // "N/A"')
ROTATION_PERIOD=$(echo $CREDS_RESPONSE | jq -r '.data.rotation_period // "N/A"')

log_success "Successfully retrieved static credentials"
log "  Client ID: ${CLIENT_ID}"
log "  New client secret (truncated): ${AFTER_SECRET_TRUNCATED}"
log "  Last Rotation: ${LAST_VAULT_ROTATION}"
log "  TTL: ${TTL}"
log "  Rotation Period: ${ROTATION_PERIOD}"
echo ""

# Step 5: Verify rotation occurred
log_step "Step 5: Verifying rotation occurred..."

if [ -n "$BEFORE_ROTATION" ] && [ "$BEFORE_ROTATION" != "N/A" ] && [ "$LAST_VAULT_ROTATION" != "N/A" ]; then
    if [ "$BEFORE_ROTATION" != "$LAST_VAULT_ROTATION" ]; then
        log_success "Rotation confirmed!"
        log "  Previous timestamp: ${BEFORE_ROTATION}"
        log "  New timestamp: ${LAST_VAULT_ROTATION}"
        if [ -n "$BEFORE_SECRET" ] && [ "$BEFORE_SECRET" != "$AFTER_SECRET" ]; then
            log "  Previous secret: ${BEFORE_SECRET_TRUNCATED}"
            log "  New secret: ${AFTER_SECRET_TRUNCATED}"
        fi
    else
        echo -e "${YELLOW}  ⚠ Warning: Rotation timestamp unchanged. Rotation may have failed or was very recent.${NC}"
    fi
else
    log_success "Rotation completed (unable to compare timestamps)"
fi
echo ""

# Step 6: Verify credentials are valid by attempting to list Azure roles
log_step "Step 6: Verifying static credentials configuration in Vault..."

set +e  # Temporarily disable exit on error
ROLE_INFO=$(vault read -format=json azure/static-roles/${VAULT_STATIC_ROLE_NAME} 2>&1)
ROLE_READ_EXIT=$?
set -e  # Re-enable exit on error

if [ $ROLE_READ_EXIT -eq 0 ]; then
    APP_OBJECT_ID=$(echo $ROLE_INFO | jq -r '.data.application_object_id // "N/A"')
    TTL_CONFIG=$(echo $ROLE_INFO | jq -r '.data.ttl // "N/A"')
    ROTATION_PERIOD_CONFIG=$(echo $ROLE_INFO | jq -r '.data.rotation_period // "N/A"')
    
    log "  Role configuration:"
    log "    Application Object ID: ${APP_OBJECT_ID}"
    log "    Configured TTL: ${TTL_CONFIG}"
    log "    Rotation Period: ${ROTATION_PERIOD_CONFIG}"
else
    log "  Warning: Could not read role configuration details"
fi
echo ""

# Step 7: Revoke Vault token
log_step "Step 7: Cleaning up..."
vault token revoke -self >/dev/null 2>&1

if [ $? -eq 0 ]; then
    log_success "Successfully revoked Vault token"
else
    log "  Warning: Failed to revoke Vault token (may have already expired)"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Rotation completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
exit 0

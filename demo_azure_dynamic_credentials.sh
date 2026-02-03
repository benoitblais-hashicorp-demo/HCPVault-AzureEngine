#!/bin/bash

# Demo script for Vault Azure Dynamic Credentials
# This script demonstrates how an application can retrieve and use temporary Azure credentials from Vault
# Authentication: AppRole (Role ID + Secret ID)

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
VAULT_ROLE_NAME="${VAULT_ROLE_NAME:-hcpvault-demo-existingobjectid}"
APPROLE_PATH="${APPROLE_PATH:-approle}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Vault Azure Dynamic Credentials Demo${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Step 1: Verify required environment variables
echo -e "${YELLOW}Step 1: Verifying configuration...${NC}"

if [ -z "$VAULT_ADDR" ]; then
    echo -e "${RED}Error: VAULT_ADDR environment variable not set${NC}"
    exit 1
fi

if [ -z "$VAULT_NAMESPACE" ]; then
    echo -e "${RED}Error: VAULT_NAMESPACE environment variable not set${NC}"
    exit 1
fi

if [ -z "$VAULT_DYNAMIC_ROLE_ID" ]; then
    echo -e "${RED}Error: VAULT_DYNAMIC_ROLE_ID environment variable not set${NC}"
    exit 1
fi

if [ -z "$VAULT_DYNAMIC_SECRET_ID" ]; then
    echo -e "${RED}Error: VAULT_DYNAMIC_SECRET_ID environment variable not set${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration verified${NC}"
echo -e "  Vault Address: ${VAULT_ADDR}"
echo -e "  Vault Namespace: ${VAULT_NAMESPACE}"
echo -e "  AppRole Path: ${APPROLE_PATH}"
echo -e "  Role ID: ${VAULT_DYNAMIC_ROLE_ID:0:20}..."
echo -e "  Secret ID: ${VAULT_DYNAMIC_SECRET_ID:0:20}...\n"

# Step 2: Authenticate to Vault using AppRole
echo -e "${YELLOW}Step 2: Authenticating to Vault using AppRole...${NC}"

AUTH_RESPONSE=$(vault write -format=json auth/${APPROLE_PATH}/login \
    role_id="${VAULT_DYNAMIC_ROLE_ID}" \
    secret_id="${VAULT_DYNAMIC_SECRET_ID}")

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to authenticate to Vault${NC}"
    exit 1
fi

# Extract and set the token
VAULT_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.auth.client_token')
export VAULT_TOKEN

TOKEN_TTL=$(echo $AUTH_RESPONSE | jq -r '.auth.lease_duration')
TOKEN_POLICIES=$(echo $AUTH_RESPONSE | jq -r '.auth.policies | join(", ")')

echo -e "${GREEN}✓ Successfully authenticated to Vault${NC}"
echo -e "  Token TTL: ${TOKEN_TTL} seconds ($(($TOKEN_TTL / 60)) minutes)"
echo -e "  Token Policies: ${TOKEN_POLICIES}\n"

# Step 2: Request dynamic Azure credentials
echo -e "${YELLOW}Step 3: Requesting dynamic Azure credentials from Vault...${NC}"
echo -e "Role: ${VAULT_ROLE_NAME}"

CREDS_JSON=$(vault read -format=json azure/creds/${VAULT_ROLE_NAME})

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to retrieve credentials from Vault${NC}"
    exit 1
fi

# Extract credential details
CLIENT_ID=$(echo $CREDS_JSON | jq -r '.data.client_id')
CLIENT_SECRET=$(echo $CREDS_JSON | jq -r '.data.client_secret')
LEASE_ID=$(echo $CREDS_JSON | jq -r '.lease_id')
LEASE_DURATION=$(echo $CREDS_JSON | jq -r '.lease_duration')
LEASE_RENEWABLE=$(echo $CREDS_JSON | jq -r '.lease_renewable')

echo -e "${GREEN}✓ Successfully retrieved dynamic credentials${NC}"
echo -e "  Client ID: ${CLIENT_ID}"
echo -e "  Client Secret: ${CLIENT_SECRET:0:8}... (masked)"
echo -e "  Lease ID: ${LEASE_ID}"
echo -e "  Lease Duration: ${LEASE_DURATION} seconds ($(($LEASE_DURATION / 60)) minutes)"
echo -e "  Lease Renewable: ${LEASE_RENEWABLE}\n"

# Step 3a: Demonstrate least-privilege access control
echo -e "${YELLOW}Step 3a: Testing least-privilege access (attempting to read static credentials)...${NC}"
STATIC_ROLE_NAME="${STATIC_ROLE_NAME:-HCPVault-Demo-Static}"
echo -e "Attempting to read: azure/static-creds/${STATIC_ROLE_NAME}"

STATIC_ATTEMPT=$(vault read -format=json azure/static-creds/${STATIC_ROLE_NAME} 2>&1)
STATIC_EXIT_CODE=$?

if [ $STATIC_EXIT_CODE -ne 0 ]; then
    echo -e "${GREEN}✓ Access denied as expected (least-privilege enforcement)${NC}"
    echo -e "  This AppRole can only read dynamic credentials"
    echo -e "  Error: $(echo $STATIC_ATTEMPT | jq -r '.errors[0]' 2>/dev/null || echo 'Permission denied')\n"
else
    echo -e "${RED}⚠ Warning: Unexpectedly succeeded in reading static credentials${NC}"
    echo -e "  This may indicate overly permissive policies\n"
fi

# Step 4: Login to Azure using dynamic credentials
echo -e "${YELLOW}Step 4: Authenticating to Azure with dynamic credentials...${NC}"

# Get tenant ID from environment or prompt
if [ -z "$AZURE_TENANT_ID" ]; then
    echo -e "${RED}Error: AZURE_TENANT_ID environment variable not set${NC}"
    echo -e "Please set your Azure Tenant ID:"
    read -p "AZURE_TENANT_ID: " AZURE_TENANT_ID
fi

az login --service-principal \
    --username "$CLIENT_ID" \
    --password "$CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID" \
    --output table

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to authenticate to Azure${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Successfully authenticated to Azure${NC}\n"

# Step 5: Display Azure account information
echo -e "${YELLOW}Step 5: Displaying Azure account information...${NC}"
echo -e "\n${BLUE}Account Details:${NC}"
az account show --output table

echo -e "\n${BLUE}Subscriptions:${NC}"
az account list --output table

echo -e "\n${BLUE}Resource Groups (first 10):${NC}"
az group list --output table --query "[].{Name:name, Location:location, Status:properties.provisioningState}" | head -n 12

# Step 6: Demonstrate credential lifecycle
echo -e "\n${YELLOW}Step 6: Credential Lifecycle Information${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "These credentials are temporary and will expire in ${LEASE_DURATION} seconds."
echo -e "After expiration, they will be automatically revoked by Vault."
echo -e "\n${BLUE}Key Benefits:${NC}"
echo -e "  • No long-lived credentials stored in your application"
echo -e "  • Automatic credential rotation"
echo -e "  • Centralized access control and auditing"
echo -e "  • Reduced risk of credential leakage"

# Step 7: Cleanup (logout from Azure)
echo -e "\n${YELLOW}Step 7: Cleaning up...${NC}"
az logout
echo -e "${GREEN}✓ Logged out from Azure${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Demo completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

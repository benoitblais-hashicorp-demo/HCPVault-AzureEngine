#!/usr/bin/env bash
# Script to authenticate with Vault using AppRole and read Azure SPN secret for HCPVault-Demo-ExistingObjectID
# Usage: ./get_azure_spn_secret_approle.sh <vault_addr> <role_id> <secret_id> <vault_path>

set -e

VAULT_ADDR="$1"
ROLE_ID="$2"
SECRET_ID="$3"
VAULT_PATH="$4"

if [ -z "$VAULT_ADDR" ] || [ -z "$ROLE_ID" ] || [ -z "$SECRET_ID" ] || [ -z "$VAULT_PATH" ]; then
  echo "Usage: $0 <vault_addr> <role_id> <secret_id> <vault_path>"
  exit 1
fi

# Authenticate with Vault using AppRole
VAULT_TOKEN=$(curl -s --request POST --data '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' "$VAULT_ADDR/v1/auth/approle/login" | jq -r .auth.client_token)

if [ "$VAULT_TOKEN" == "null" ] || [ -z "$VAULT_TOKEN" ]; then
  echo "Error authenticating with Vault AppRole."
  exit 1
fi

# Read the Azure SPN secret
response=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$VAULT_PATH")

if echo "$response" | grep -q 'errors'; then
  echo "Error fetching secret: $response"
  exit 1
fi

echo "Azure SPN Secret for HCPVault-Demo-ExistingObjectID:"
echo "$response" | jq

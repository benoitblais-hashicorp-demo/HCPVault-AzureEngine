#!/usr/bin/env bash
# Script to authenticate with Vault using AppRole and read Azure SPN secret for the configured role
# Usage: ./get_azure_spn_secret_dynamic.sh <vault_addr> <role_id> <role_name> <vault_path>

set -e

VAULT_ADDR="$1"
ROLE_ID="$2"
ROLE_NAME="$3"
VAULT_PATH="$4"

if [ -z "$VAULT_ADDR" ] || [ -z "$ROLE_ID" ] || [ -z "$ROLE_NAME" ] || [ -z "$VAULT_PATH" ]; then
  echo "Usage: $0 <vault_addr> <role_id> <role_name> <vault_path>"
  exit 1
fi

# Generate a secret_id for the AppRole
SECRET_ID=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST "$VAULT_ADDR/v1/auth/approle/role/$ROLE_NAME/secret-id" | jq -r .data.secret_id)

if [ "$SECRET_ID" == "null" ] || [ -z "$SECRET_ID" ]; then
  echo "Error generating secret_id for AppRole."
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

echo "Azure SPN Secret for $ROLE_NAME:"
echo "$response" | jq

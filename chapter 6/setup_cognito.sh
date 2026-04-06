#!/bin/bash
# Set up a Cognito user pool for AgentCore OAuth authentication.
#
# Prerequisites:
#   export REGION=us-east-1
#   export USERNAME=testuser
#   export PASSWORD=YourPassword123!
#
# Usage: source setup_cognito.sh
#
# Outputs: POOL_ID, CLIENT_ID, BEARER_TOKEN, and Discovery URL

set -e

if [ -z "$REGION" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Error: Set REGION, USERNAME, and PASSWORD environment variables first."
    exit 1
fi

# Create User Pool
export POOL_ID=$(aws cognito-idp create-user-pool \
  --pool-name "AgentCoreUserPool" \
  --policies '{"PasswordPolicy":{"MinimumLength":8}}' \
  --region "$REGION" | jq -r '.UserPool.Id')

# Create App Client
export CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --user-pool-id "$POOL_ID" \
  --client-name "AgentCoreClient" \
  --no-generate-secret \
  --explicit-auth-flows "ALLOW_USER_PASSWORD_AUTH" "ALLOW_REFRESH_TOKEN_AUTH" \
  --region "$REGION" | jq -r '.UserPoolClient.ClientId')

# Create User
aws cognito-idp admin-create-user \
  --user-pool-id "$POOL_ID" \
  --username "$USERNAME" \
  --region "$REGION" \
  --message-action SUPPRESS > /dev/null

# Set Permanent Password
aws cognito-idp admin-set-user-password \
  --user-pool-id "$POOL_ID" \
  --username "$USERNAME" \
  --password "$PASSWORD" \
  --region "$REGION" \
  --permanent > /dev/null

# Get Bearer Token
export BEARER_TOKEN=$(aws cognito-idp initiate-auth \
  --client-id "$CLIENT_ID" \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME="$USERNAME",PASSWORD="$PASSWORD" \
  --region "$REGION" | jq -r '.AuthenticationResult.AccessToken')

echo ""
echo "Pool ID:       $POOL_ID"
echo "Client ID:     $CLIENT_ID"
echo "Discovery URL: https://cognito-idp.$REGION.amazonaws.com/$POOL_ID/.well-known/openid-configuration"
echo "Bearer Token:  $BEARER_TOKEN"

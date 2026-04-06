#!/bin/bash
set -e

STACK_NAME="document-analysis-agent"
REGION="${AWS_REGION:-us-east-1}"

# Auto-detect architecture: arm64 for Apple Silicon / Graviton, x86_64 for Intel
MACHINE_ARCH=$(uname -m)
if [ "$MACHINE_ARCH" = "arm64" ] || [ "$MACHINE_ARCH" = "aarch64" ]; then
  LAMBDA_ARCH="arm64"
else
  LAMBDA_ARCH="x86_64"
fi

echo "=== Deploying Strands Agent to AWS Lambda ==="
echo ""

# Verify prerequisites
echo "Checking prerequisites..."

if ! command -v sam &> /dev/null; then
  echo "ERROR: AWS SAM CLI is not installed."
  echo "  Install: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
  exit 1
fi

if ! command -v docker &> /dev/null; then
  echo "ERROR: Docker is not installed."
  exit 1
fi

if ! docker info &> /dev/null; then
  echo "ERROR: Docker is not running. Start Docker Desktop and try again."
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
  echo "ERROR: AWS credentials not configured. Run 'aws configure' first."
  exit 1
}

echo "  Account: $ACCOUNT_ID"
echo "  Region:  $REGION"
echo "  Arch:    $LAMBDA_ARCH"
echo "  SAM CLI: $(sam --version)"
echo ""

# --- Step 1: Build ---
echo "Step 1: Building container image (this takes 1-2 minutes the first time)..."
# Clean previous build artifacts to avoid cache issues
rm -rf .aws-sam 2>/dev/null || true
sam build
echo ""

# --- Step 2: Deploy ---
echo "Step 2: Deploying to AWS (this takes 2-3 minutes)..."
sam deploy \
  --stack-name $STACK_NAME \
  --resolve-s3 \
  --resolve-image-repos \
  --capabilities CAPABILITY_IAM \
  --region $REGION \
  --parameter-overrides Architecture=$LAMBDA_ARCH \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset
echo ""

# --- Step 3: Get the endpoint ---
echo "=== Deployment complete ==="
echo ""

API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
  --output text \
  --region $REGION)

echo "Endpoint: $API_ENDPOINT"
echo ""
echo "Test it:"
echo "  curl -X POST $API_ENDPOINT \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"document_text\": \"This agreement is entered into by Party A and Party B. Party A shall deliver 1000 units by March 2026.\"}'"
echo ""
echo "Note: The first request will be slow (cold start, 5-15 seconds). Subsequent requests are faster."

#!/bin/bash
set -e

STACK_NAME="document-analysis-agent"
REGION="${AWS_REGION:-us-east-1}"

echo "=== Cleaning up Lambda deployment ==="
echo ""

echo "Deleting stack '$STACK_NAME'..."
sam delete \
  --stack-name $STACK_NAME \
  --region $REGION \
  --no-prompts

echo ""
echo "=== Cleanup complete. All resources removed. ==="

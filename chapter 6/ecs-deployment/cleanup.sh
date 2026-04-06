#!/usr/bin/env bash
set -euo pipefail

# ── Configuration (must match deploy.sh) ───────────────────────────
APP_NAME="hospital-scheduling-agent"
CLUSTER_NAME="agent-cluster"
SERVICE_NAME="scheduling-agent-service"
TASK_FAMILY="scheduling-agent"
EXEC_ROLE_NAME="${APP_NAME}-exec-role"
TASK_ROLE_NAME="${APP_NAME}-task-role"
ALB_NAME="${APP_NAME}-alb"
TG_NAME="${APP_NAME}-tg"
ALB_SG_NAME="${APP_NAME}-alb-sg"
ECS_SG_NAME="${APP_NAME}-ecs-sg"

REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== Cleaning up Hospital Scheduling Agent ==="
echo ""

# ── Delete ECS service ─────────────────────────────────────────────
echo "Deleting ECS service..."
aws ecs update-service --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" \
  --desired-count 0 --region "${REGION}" --output text 2>/dev/null || true
aws ecs delete-service --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" \
  --force --region "${REGION}" --output text 2>/dev/null || true
echo "  Waiting for tasks to drain..."
sleep 15

# ── Delete ALB resources ──────────────────────────────────────────
echo "Deleting ALB resources..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names "${ALB_NAME}" \
  --region "${REGION}" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)
if [ -n "${ALB_ARN}" ] && [ "${ALB_ARN}" != "None" ]; then
  # Delete listeners first
  LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn "${ALB_ARN}" \
    --region "${REGION}" --query 'Listeners[*].ListenerArn' --output text 2>/dev/null || true)
  for arn in ${LISTENERS}; do
    aws elbv2 delete-listener --listener-arn "${arn}" --region "${REGION}" 2>/dev/null || true
  done
  aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" --region "${REGION}" 2>/dev/null || true
fi

TG_ARN=$(aws elbv2 describe-target-groups --names "${TG_NAME}" \
  --region "${REGION}" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -n "${TG_ARN}" ] && [ "${TG_ARN}" != "None" ]; then
  aws elbv2 delete-target-group --target-group-arn "${TG_ARN}" --region "${REGION}" 2>/dev/null || true
fi
echo "  ALB and target group deleted."

# ── Deregister task definitions ────────────────────────────────────
echo "Deregistering task definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix "${TASK_FAMILY}" \
  --region "${REGION}" --query 'taskDefinitionArns' --output text 2>/dev/null || true)
for td in ${TASK_DEFS}; do
  aws ecs deregister-task-definition --task-definition "${td}" --region "${REGION}" --output text 2>/dev/null || true
done

# ── Delete ECS cluster ─────────────────────────────────────────────
echo "Deleting ECS cluster..."
aws ecs delete-cluster --cluster "${CLUSTER_NAME}" --region "${REGION}" --output text 2>/dev/null || true

# ── Delete ECR repository ─────────────────────────────────────────
echo "Deleting ECR repository..."
aws ecr delete-repository --repository-name "${APP_NAME}" --force --region "${REGION}" --output text 2>/dev/null || true

# ── Delete CloudWatch log group ────────────────────────────────────
echo "Deleting log group..."
aws logs delete-log-group --log-group-name "/ecs/${TASK_FAMILY}" --region "${REGION}" 2>/dev/null || true

# ── Delete security groups ─────────────────────────────────────────
echo "Deleting security groups..."
# Wait for ALB to fully release the SGs
echo "  Waiting for ALB to release network interfaces..."
sleep 30

VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --region "${REGION}" --query 'Vpcs[0].VpcId' --output text)

for SG_NAME in "${ECS_SG_NAME}" "${ALB_SG_NAME}"; do
  SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="${SG_NAME}" Name=vpc-id,Values="${VPC_ID}" \
    --region "${REGION}" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
  if [ -n "${SG_ID}" ] && [ "${SG_ID}" != "None" ]; then
    aws ec2 delete-security-group --group-id "${SG_ID}" --region "${REGION}" 2>/dev/null || true
  fi
done
echo "  Security groups deleted."

# ── Delete IAM roles ──────────────────────────────────────────────
echo "Deleting IAM roles..."
# Task role
aws iam delete-role-policy --role-name "${TASK_ROLE_NAME}" --policy-name BedrockAccess 2>/dev/null || true
aws iam delete-role --role-name "${TASK_ROLE_NAME}" 2>/dev/null || true

# Execution role
aws iam detach-role-policy --role-name "${EXEC_ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true
aws iam delete-role --role-name "${EXEC_ROLE_NAME}" 2>/dev/null || true
echo "  IAM roles deleted."

echo ""
echo "=== Cleanup complete ==="
echo "All resources for ${APP_NAME} have been removed."

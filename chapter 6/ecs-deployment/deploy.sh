#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────
APP_NAME="hospital-scheduling-agent"
CLUSTER_NAME="agent-cluster"
SERVICE_NAME="scheduling-agent-service"
TASK_FAMILY="scheduling-agent"
CONTAINER_PORT=8080
CPU=1024        # 1 vCPU
MEMORY=2048     # 2 GB
DESIRED_COUNT=1
MODEL_ID="us.anthropic.claude-sonnet-4-20250514-v1:0"

REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${APP_NAME}"
IMAGE_TAG="latest"

echo "=== Hospital Scheduling Agent - ECS Fargate Deployment ==="
echo "Region:  ${REGION}"
echo "Account: ${ACCOUNT_ID}"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────
echo "Checking prerequisites..."
for cmd in aws docker; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is not installed." && exit 1
  fi
done
docker info &>/dev/null || { echo "ERROR: Docker is not running."; exit 1; }
aws sts get-caller-identity &>/dev/null || { echo "ERROR: AWS credentials not configured."; exit 1; }
echo "All prerequisites met."
echo ""

# ── Step 1: Create ECR repository ─────────────────────────────────
echo "Step 1/7: Creating ECR repository..."
aws ecr describe-repositories --repository-names "${APP_NAME}" --region "${REGION}" &>/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "${APP_NAME}" --region "${REGION}" --output text --query 'repository.repositoryUri'
echo "  ECR repo: ${ECR_REPO}"

# ── Step 2: Build and push Docker image ────────────────────────────
echo "Step 2/7: Building and pushing Docker image..."
aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

docker build --platform linux/amd64 -t "${APP_NAME}:${IMAGE_TAG}" .
docker tag "${APP_NAME}:${IMAGE_TAG}" "${ECR_REPO}:${IMAGE_TAG}"
docker push "${ECR_REPO}:${IMAGE_TAG}"
echo "  Image pushed: ${ECR_REPO}:${IMAGE_TAG}"

# ── Step 3: Create IAM roles ──────────────────────────────────────
echo "Step 3/7: Creating IAM roles..."

# Task execution role (ECS uses this to pull images and write logs)
EXEC_ROLE_NAME="${APP_NAME}-exec-role"
if ! aws iam get-role --role-name "${EXEC_ROLE_NAME}" &>/dev/null 2>&1; then
  aws iam create-role \
    --role-name "${EXEC_ROLE_NAME}" \
    --assume-role-policy-document '{
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": {"Service": "ecs-tasks.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }]
    }' --output text --query 'Role.Arn'
  aws iam attach-role-policy \
    --role-name "${EXEC_ROLE_NAME}" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
fi
EXEC_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${EXEC_ROLE_NAME}"
echo "  Execution role: ${EXEC_ROLE_NAME}"

# Task role (your agent code uses this to call Bedrock)
TASK_ROLE_NAME="${APP_NAME}-task-role"
if ! aws iam get-role --role-name "${TASK_ROLE_NAME}" &>/dev/null 2>&1; then
  aws iam create-role \
    --role-name "${TASK_ROLE_NAME}" \
    --assume-role-policy-document '{
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": {"Service": "ecs-tasks.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }]
    }' --output text --query 'Role.Arn'
  aws iam put-role-policy \
    --role-name "${TASK_ROLE_NAME}" \
    --policy-name BedrockAccess \
    --policy-document "{
      \"Version\": \"2012-10-17\",
      \"Statement\": [{
        \"Effect\": \"Allow\",
        \"Action\": [\"bedrock:InvokeModel\", \"bedrock:InvokeModelWithResponseStream\"],
        \"Resource\": [
          \"arn:aws:bedrock:*::foundation-model/*\",
          \"arn:aws:bedrock:*:${ACCOUNT_ID}:inference-profile/*\"
        ]
      }]
    }"
fi
TASK_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${TASK_ROLE_NAME}"
echo "  Task role: ${TASK_ROLE_NAME}"

# Brief pause for IAM propagation
sleep 10

# ── Step 4: Create ECS cluster ────────────────────────────────────
echo "Step 4/7: Creating ECS cluster..."
aws ecs describe-clusters --clusters "${CLUSTER_NAME}" --region "${REGION}" \
  --query 'clusters[?status==`ACTIVE`].clusterName' --output text | grep -q "${CLUSTER_NAME}" 2>/dev/null || \
  aws ecs create-cluster --cluster-name "${CLUSTER_NAME}" --region "${REGION}" --output text --query 'cluster.clusterArn'
echo "  Cluster: ${CLUSTER_NAME}"

# ── Step 5: Create CloudWatch log group ───────────────────────────
LOG_GROUP="/ecs/${TASK_FAMILY}"
echo "Step 5/7: Creating CloudWatch log group..."
aws logs describe-log-groups --log-group-name-prefix "${LOG_GROUP}" --region "${REGION}" \
  --query "logGroups[?logGroupName=='${LOG_GROUP}'].logGroupName" --output text | grep -q "${LOG_GROUP}" 2>/dev/null || \
  aws logs create-log-group --log-group-name "${LOG_GROUP}" --region "${REGION}"
echo "  Log group: ${LOG_GROUP}"

# ── Step 6: Register task definition ──────────────────────────────
echo "Step 6/7: Registering task definition..."
TASK_DEF=$(cat <<EOF
{
  "family": "${TASK_FAMILY}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",
  "executionRoleArn": "${EXEC_ROLE_ARN}",
  "taskRoleArn": "${TASK_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "${APP_NAME}",
      "image": "${ECR_REPO}:${IMAGE_TAG}",
      "essential": true,
      "portMappings": [{"containerPort": ${CONTAINER_PORT}, "protocol": "tcp"}],
      "environment": [
        {"name": "MODEL_ID", "value": "${MODEL_ID}"}
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:${CONTAINER_PORT}/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${LOG_GROUP}",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "agent"
        }
      }
    }
  ]
}
EOF
)
echo "${TASK_DEF}" > /tmp/task-def.json
aws ecs register-task-definition --cli-input-json file:///tmp/task-def.json \
  --region "${REGION}" --output text --query 'taskDefinition.taskDefinitionArn'
rm /tmp/task-def.json
echo "  Task definition: ${TASK_FAMILY}"

# ── Step 7: Create ALB, target group, security groups, and service ─
echo "Step 7/7: Creating ALB, security groups, and ECS service..."

# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --region "${REGION}" --query 'Vpcs[0].VpcId' --output text)

# Find the Internet Gateway for this VPC
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters Name=attachment.vpc-id,Values="${VPC_ID}" \
  --region "${REGION}" --query 'InternetGateways[0].InternetGatewayId' --output text)

# Find subnets whose route table sends 0.0.0.0/0 through the IGW.
# An internet-facing ALB requires this; subnets routed through a NAT gateway won't work.
PUBLIC_SUBNETS=()
ALL_SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="${VPC_ID}" Name=default-for-az,Values=true \
  --region "${REGION}" --query 'Subnets[*].SubnetId' --output text)
for SID in ${ALL_SUBNETS}; do
  # Get the route table associated with this subnet (explicit or main)
  RT_ID=$(aws ec2 describe-route-tables \
    --filters Name=association.subnet-id,Values="${SID}" \
    --region "${REGION}" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null)
  if [ -z "${RT_ID}" ] || [ "${RT_ID}" = "None" ]; then
    # No explicit association: uses the VPC main route table
    RT_ID=$(aws ec2 describe-route-tables \
      --filters Name=vpc-id,Values="${VPC_ID}" Name=association.main,Values=true \
      --region "${REGION}" --query 'RouteTables[0].RouteTableId' --output text)
  fi
  # Check if the default route points to an IGW
  GW=$(aws ec2 describe-route-tables --route-table-ids "${RT_ID}" \
    --region "${REGION}" \
    --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" --output text)
  if [ "${GW}" = "${IGW_ID}" ]; then
    PUBLIC_SUBNETS+=("${SID}")
  fi
done

if [ "${#PUBLIC_SUBNETS[@]}" -lt 2 ]; then
  echo "ERROR: Need at least 2 public subnets (routed through IGW) for the ALB."
  echo "       Found ${#PUBLIC_SUBNETS[@]}. Check your VPC route tables."
  exit 1
fi
SUBNET_1="${PUBLIC_SUBNETS[0]}"
SUBNET_2="${PUBLIC_SUBNETS[1]}"
echo "  Public subnets: ${SUBNET_1}, ${SUBNET_2}"

# Security group for ALB (allow inbound HTTP from anywhere)
ALB_SG_NAME="${APP_NAME}-alb-sg"
ALB_SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="${ALB_SG_NAME}" Name=vpc-id,Values="${VPC_ID}" \
  --region "${REGION}" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
if [ "${ALB_SG_ID}" = "None" ] || [ -z "${ALB_SG_ID}" ]; then
  ALB_SG_ID=$(aws ec2 create-security-group --group-name "${ALB_SG_NAME}" \
    --description "ALB security group for ${APP_NAME}" --vpc-id "${VPC_ID}" \
    --region "${REGION}" --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress --group-id "${ALB_SG_ID}" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "${REGION}" --output text
fi
echo "  ALB security group: ${ALB_SG_ID}"

# Security group for ECS tasks (allow inbound from ALB only)
ECS_SG_NAME="${APP_NAME}-ecs-sg"
ECS_SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="${ECS_SG_NAME}" Name=vpc-id,Values="${VPC_ID}" \
  --region "${REGION}" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
if [ "${ECS_SG_ID}" = "None" ] || [ -z "${ECS_SG_ID}" ]; then
  ECS_SG_ID=$(aws ec2 create-security-group --group-name "${ECS_SG_NAME}" \
    --description "ECS tasks security group for ${APP_NAME}" --vpc-id "${VPC_ID}" \
    --region "${REGION}" --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress --group-id "${ECS_SG_ID}" \
    --protocol tcp --port "${CONTAINER_PORT}" --source-group "${ALB_SG_ID}" \
    --region "${REGION}" --output text
fi
echo "  ECS security group: ${ECS_SG_ID}"

# Create ALB
ALB_NAME="${APP_NAME}-alb"
ALB_ARN=$(aws elbv2 describe-load-balancers --names "${ALB_NAME}" \
  --region "${REGION}" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)
if [ -z "${ALB_ARN}" ] || [ "${ALB_ARN}" = "None" ]; then
  ALB_ARN=$(aws elbv2 create-load-balancer --name "${ALB_NAME}" \
    --subnets "${SUBNET_1}" "${SUBNET_2}" \
    --security-groups "${ALB_SG_ID}" \
    --scheme internet-facing --type application \
    --region "${REGION}" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
fi
echo "  ALB: ${ALB_NAME}"

# Create target group
TG_NAME="${APP_NAME}-tg"
TG_ARN=$(aws elbv2 describe-target-groups --names "${TG_NAME}" \
  --region "${REGION}" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "${TG_ARN}" ] || [ "${TG_ARN}" = "None" ]; then
  TG_ARN=$(aws elbv2 create-target-group --name "${TG_NAME}" \
    --protocol HTTP --port "${CONTAINER_PORT}" --vpc-id "${VPC_ID}" \
    --target-type ip \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --region "${REGION}" --query 'TargetGroups[0].TargetGroupArn' --output text)
fi
echo "  Target group: ${TG_NAME}"

# Create listener
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "${ALB_ARN}" \
  --region "${REGION}" --query 'Listeners[0].ListenerArn' --output text 2>/dev/null || true)
if [ -z "${LISTENER_ARN}" ] || [ "${LISTENER_ARN}" = "None" ]; then
  aws elbv2 create-listener --load-balancer-arn "${ALB_ARN}" \
    --protocol HTTP --port 80 \
    --default-actions Type=forward,TargetGroupArn="${TG_ARN}" \
    --region "${REGION}" --output text --query 'Listeners[0].ListenerArn'
fi

# Create ECS service
SERVICE_EXISTS=$(aws ecs describe-services --cluster "${CLUSTER_NAME}" --services "${SERVICE_NAME}" \
  --region "${REGION}" --query 'services[?status==`ACTIVE`].serviceName' --output text 2>/dev/null || true)
if [ -z "${SERVICE_EXISTS}" ]; then
  aws ecs create-service \
    --cluster "${CLUSTER_NAME}" \
    --service-name "${SERVICE_NAME}" \
    --task-definition "${TASK_FAMILY}" \
    --desired-count "${DESIRED_COUNT}" \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_1},${SUBNET_2}],securityGroups=[${ECS_SG_ID}],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=${TG_ARN},containerName=${APP_NAME},containerPort=${CONTAINER_PORT}" \
    --health-check-grace-period-seconds 120 \
    --region "${REGION}" --output text --query 'service.serviceArn'
else
  # Update existing service with new task definition
  aws ecs update-service \
    --cluster "${CLUSTER_NAME}" \
    --service "${SERVICE_NAME}" \
    --task-definition "${TASK_FAMILY}" \
    --force-new-deployment \
    --region "${REGION}" --output text --query 'service.serviceArn'
fi

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers --names "${ALB_NAME}" \
  --region "${REGION}" --query 'LoadBalancers[0].DNSName' --output text)

echo ""
echo "=== Deployment started ==="
echo ""
echo "The ECS service is launching. It takes 2-3 minutes for the task to"
echo "start and pass health checks."
echo ""
echo "Monitor progress:"
echo "  aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --query 'services[0].deployments' --region ${REGION}"
echo ""
echo "Once healthy, open in your browser:"
echo "  http://${ALB_DNS}"
echo ""
echo "Or test with curl:"
echo "  curl -X POST http://${ALB_DNS}/schedule -H 'Content-Type: application/json' -d '{\"message\": \"I need to schedule a knee arthroscopy for patient P-1234 with Dr. Smith next Tuesday\"}'"
echo ""
echo "Endpoint: http://${ALB_DNS}"
echo ""
echo "View logs:"
echo "  aws logs tail ${LOG_GROUP} --follow --region ${REGION}"

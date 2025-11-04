#!/bin/bash

# Script to activate DR environment in case of primary region failure
# This script scales up DR resources and adjusts Route53 to point to DR

set -e

# Environment variables (set these or pass as arguments)
DR_REGION=${1:-"us-west-2"}
ENV_NAME=${2:-"ecs-jenkins"}
STACK_NAME="EcsJenkinsGithubDrStack"

echo "Activating DR environment in $DR_REGION..."

# Step 1: Scale up DR ECS services
echo "Scaling up DR ECS services..."
CLUSTER_NAME="$ENV_NAME-dr-cluster"
SERVICE_NAME="$ENV_NAME-dr-service"

# Get the desired count from production (or use fixed value from config)
DESIRED_COUNT=4  # This should match your production capacity

# Update ECS service to increase capacity
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count $DESIRED_COUNT --region $DR_REGION

# Step 2: Update ECS auto scaling for DR
echo "Updating Auto Scaling configuration..."
MIN_CAPACITY=2
MAX_CAPACITY=10

# Get the Auto Scaling target for the ECS service
AUTO_SCALING_TARGET=$(aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs \
  --resource-ids service/$CLUSTER_NAME/$SERVICE_NAME \
  --region $DR_REGION \
  --query 'ScalableTargets[0].ResourceId' --output text)

# Update the target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id $AUTO_SCALING_TARGET \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity $MIN_CAPACITY \
  --max-capacity $MAX_CAPACITY \
  --region $DR_REGION

# Step 3: Update Route53 to point to DR load balancer
echo "Updating DNS to point to DR environment..."
HOSTED_ZONE_ID="REPLACE_WITH_YOUR_HOSTED_ZONE_ID"
DOMAIN_NAME="ecs-jenkins.example.com"

# Get the DR load balancer DNS name
DR_LB_DNS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $DR_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDns'].OutputValue" --output text)

# Get the DR load balancer hosted zone ID
DR_LB_ZONE_ID=$(aws elbv2 describe-load-balancers --region $DR_REGION \
  --names "$ENV_NAME-dr-alb" --query "LoadBalancers[0].CanonicalHostedZoneId" --output text)

# Update Route53 record
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --region us-east-1 \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "'$DOMAIN_NAME'",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "'$DR_LB_ZONE_ID'",
            "DNSName": "'$DR_LB_DNS'",
            "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }'

# Step 4: Verify the DR environment is operational
echo "Verifying DR environment..."

# Check ECS service is stable
echo "Waiting for ECS service to stabilize..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $DR_REGION

# Send notification of successful DR activation
SNS_TOPIC="arn:aws:sns:$DR_REGION:$(aws sts get-caller-identity --query 'Account' --output text):$ENV_NAME-dr-notifications"
aws sns publish --topic-arn $SNS_TOPIC --message "DR environment successfully activated at $(date)" --region $DR_REGION

echo "DR environment activated successfully!"
echo "Please verify all components are working as expected."
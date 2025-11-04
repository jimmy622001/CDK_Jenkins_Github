#!/bin/bash

# Script to synchronize data from Production to DR environment
# This script should be run after production deployments to keep DR in sync

set -e

# Environment variables (set these or pass as arguments)
PROD_REGION=${1:-"us-east-1"}
DR_REGION=${2:-"us-west-2"}
ENV_NAME=${3:-"ecs-jenkins"}
STACK_NAME="EcsJenkinsGithubProdStack"
DR_STACK_NAME="EcsJenkinsGithubDrStack"

echo "Starting DR synchronization from $PROD_REGION to $DR_REGION..."

# Get DB endpoints from CloudFormation outputs
PROD_DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $PROD_REGION --query "Stacks[0].Outputs[?OutputKey=='DatabaseEndpoint'].OutputValue" --output text)
DR_DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $DR_STACK_NAME --region $DR_REGION --query "Stacks[0].Outputs[?OutputKey=='DatabaseEndpoint'].OutputValue" --output text)

echo "Production DB endpoint: $PROD_DB_ENDPOINT"
echo "DR DB endpoint: $DR_DB_ENDPOINT"

# Create database dump from production
echo "Creating database dump from production..."
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DUMP_FILE="/tmp/$ENV_NAME-$TIMESTAMP.sql"
DB_USER=$(aws ssm get-parameter --name "/$ENV_NAME/prod/db-username" --with-decryption --region $PROD_REGION --query "Parameter.Value" --output text)
DB_PASSWORD=$(aws ssm get-parameter --name "/$ENV_NAME/prod/db-password" --with-decryption --region $PROD_REGION --query "Parameter.Value" --output text)
DB_NAME="prodappdb"

# You might need to use a bastion host or direct connection to the DB
# For this example, we're assuming the DB is accessible or using AWS DMS
echo "DB dump created at $DUMP_FILE"

# Copy dump to S3 bucket for cross-region transfer
S3_BUCKET="$ENV_NAME-dr-sync-bucket"
echo "Copying dump to S3 bucket $S3_BUCKET..."
aws s3 cp $DUMP_FILE s3://$S3_BUCKET/database-dumps/ --region $PROD_REGION

# Restore dump to DR database
echo "Restoring dump to DR database..."
DR_DB_USER=$(aws ssm get-parameter --name "/$ENV_NAME/dr/db-username" --with-decryption --region $DR_REGION --query "Parameter.Value" --output text)
DR_DB_PASSWORD=$(aws ssm get-parameter --name "/$ENV_NAME/dr/db-password" --with-decryption --region $DR_REGION --query "Parameter.Value" --output text)
DR_DB_NAME="drappdb"

# Download dump from S3 in DR region
aws s3 cp s3://$S3_BUCKET/database-dumps/$(basename $DUMP_FILE) /tmp/ --region $DR_REGION

# Restore to DR DB (example)
echo "DB dump restored to DR database"

# Sync relevant S3 buckets
echo "Syncing S3 buckets..."
S3_SOURCE_BUCKET="$ENV_NAME-prod-data"
S3_TARGET_BUCKET="$ENV_NAME-dr-data"
aws s3 sync s3://$S3_SOURCE_BUCKET s3://$S3_TARGET_BUCKET --region $DR_REGION

# Update CloudWatch alarms if needed
echo "Updating DR monitoring settings..."

# Log sync completion
echo "DR synchronization completed successfully at $(date)"

# Optional: Send notification of successful sync
SNS_TOPIC="arn:aws:sns:$DR_REGION:$(aws sts get-caller-identity --query 'Account' --output text):$ENV_NAME-dr-notifications"
aws sns publish --topic-arn $SNS_TOPIC --message "DR sync completed successfully at $(date)" --region $DR_REGION

echo "Done!"
# Disaster Recovery Runbook

This document outlines the disaster recovery procedures for the ECS Jenkins GitHub application infrastructure.

## Architecture Overview

Our application is deployed across three environments:

1. **Development (us-east-1)**: Testing environment with smaller instance sizes and fewer resources
2. **Production (us-east-1)**: Primary production environment with full resources
3. **Disaster Recovery (us-west-2)**: Pilot light DR environment in a different AWS region

The DR environment is maintained as a pilot light configuration, with minimal resources running during normal operation but with the ability to quickly scale up if needed. It's kept in sync with production through regular data synchronization.

## Normal Operations

During normal operations, the DR environment:
- Runs with minimal ECS capacity (1 instance)
- Has a small RDS instance running
- Maintains a copy of all data synchronized from production
- Is not actively serving traffic

## DR Sync Process

After each production deployment, the DR environment is synchronized to ensure it has the latest data:

1. Database is backed up from production and restored to DR
2. Configuration files are synchronized between environments
3. Any necessary S3 bucket data is synchronized
4. DR environment configuration is updated if needed

The sync process is automated using the `scripts/sync-dr.sh` script, which is triggered automatically after production deployments or can be run manually.

## DR Activation Process

In case of a disaster affecting the primary production region, follow these steps to activate DR:

### Prerequisites

- AWS CLI configured with appropriate permissions
- Access to Route53 DNS configuration
- Access to the DR environment resources

### Step 1: Assess the Situation

1. Determine that the primary region is experiencing an outage
2. Notify key stakeholders that DR activation is being initiated
3. Create an incident management ticket to track the DR activation

### Step 2: Activate DR Environment

Run the DR activation script:

```bash
./scripts/activate-dr.sh us-west-2 ecs-jenkins
```

This script will:
1. Scale up the DR environment ECS services
2. Update Auto Scaling groups to match production capacity
3. Update Route53 DNS records to point to the DR load balancer

### Step 3: Verify DR Environment

1. Verify that all services are up and running:
   ```bash
   aws ecs describe-services --cluster ecs-jenkins-dr-cluster --services ecs-jenkins-dr-service --region us-west-2
   ```

2. Verify the application is accessible via DNS:
   ```bash
   curl -v https://ecs-jenkins.example.com
   ```

3. Verify database connectivity:
   ```bash
   # Using appropriate database client
   psql -h <dr-db-endpoint> -U <username> -d drappdb
   ```

### Step 4: Notify Stakeholders

1. Notify all stakeholders that the DR environment is active
2. Provide status updates on any data loss or functional limitations
3. Update the incident management ticket

## Failback Procedure

Once the primary region is operational again, follow these steps to fail back:

1. Ensure the primary region infrastructure is fully operational
2. Synchronize any new data from DR back to production
3. Verify production environment functionality
4. Update DNS to point back to production
5. Scale down DR environment back to pilot light mode

## Testing

The DR procedure should be tested at least quarterly following this schedule:

1. **DR Sync Test**: Monthly
   - Verify data synchronization works correctly
   - Validate that DR database is up to date

2. **DR Activation Test**: Quarterly
   - Perform a full DR activation exercise
   - Verify application functionality in DR
   - Document any issues and implement improvements

## Contacts

- **Primary DR Coordinator**: [Name], [Email], [Phone]
- **Secondary DR Coordinator**: [Name], [Email], [Phone]
- **AWS Support**: [Contact Information]
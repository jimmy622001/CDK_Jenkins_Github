#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { Aspects } from 'aws-cdk-lib';
import { EcsJenkinsGithubStack } from '../lib/ecs-jenkins-github-stack';
import { AwsSolutionsChecks, NagSuppressions } from 'cdk-nag';
import * as dotenv from 'dotenv';
import { devConfig, prodConfig, drConfig } from '../lib/constructs/config/environment-config';

// Load environment variables from .env file
dotenv.config();

const app = new cdk.App();

// Apply cdk-nag to the entire application
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));

// Dev environment
const devStack = new EcsJenkinsGithubStack(app, 'EcsJenkinsGithubDevStack', {
  awsRegion: devConfig.awsRegion,
  vpcCidr: devConfig.vpcCidr,
  publicSubnetCidrs: devConfig.publicSubnetCidrs,
  privateSubnetCidrs: devConfig.privateSubnetCidrs,
  databaseSubnetCidrs: devConfig.databaseSubnetCidrs,
  availabilityZones: devConfig.availabilityZones,
  environment: devConfig.environment,
  projectName: 'ecs-jenkins',
  containerPort: devConfig.containerPort,
  keyName: devConfig.keyName,
  jenkinsInstanceType: devConfig.jenkinsInstanceType,
  jenkinsRoleName: devConfig.jenkinsRoleName,
  dbUsername: process.env.DB_USERNAME || '', // Must be set through environment variables
  dbPassword: process.env.DB_PASSWORD || '', // Must be set through environment variables or AWS Secrets Manager
  dbName: 'devappdb',
  grafanaAdminPassword: process.env.GRAFANA_ADMIN_PASSWORD || '', // Must be set through environment variables
  domainName: devConfig.domainName,
  ec2InstanceType: devConfig.instanceType.toString(),
  minInstanceCount: devConfig.minInstanceCount,
  maxInstanceCount: devConfig.maxInstanceCount,
  desiredInstanceCount: devConfig.desiredInstanceCount,
  useSpotInstances: devConfig.useSpotInstances,
  spotPrice: devConfig.spotPrice,

  // OWASP Security settings
  blockedIpAddresses: devConfig.blockedIpAddresses,
  maxRequestSize: devConfig.maxRequestSize,
  requestLimit: devConfig.requestLimit,
  enableSecurityHub: devConfig.enableSecurityHub,

  // Stack properties
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: devConfig.awsRegion,
  },
  description: 'ECS Jenkins with GitHub integration - Dev Environment',
  tags: devConfig.tags,
});

// Add suppressions for specific rules that might not be applicable in this context
NagSuppressions.addStackSuppressions(devStack, [
  { id: 'AwsSolutions-IAM4', reason: 'Using managed policies for demo purposes' },
  { id: 'AwsSolutions-IAM5', reason: 'Using wildcards in IAM policies for demo purposes' },
  { id: 'AwsSolutions-RDS3', reason: 'Using password authentication for demonstration purposes' },
  { id: 'AwsSolutions-EC23', reason: 'Using SSH key pairs for ease of demonstration' },
]);

// Production environment
const prodStack = new EcsJenkinsGithubStack(app, 'EcsJenkinsGithubProdStack', {
  awsRegion: prodConfig.awsRegion,
  vpcCidr: prodConfig.vpcCidr,
  publicSubnetCidrs: prodConfig.publicSubnetCidrs,
  privateSubnetCidrs: prodConfig.privateSubnetCidrs,
  databaseSubnetCidrs: prodConfig.databaseSubnetCidrs,
  availabilityZones: prodConfig.availabilityZones,
  environment: prodConfig.environment,
  projectName: 'ecs-jenkins',
  containerPort: prodConfig.containerPort,
  keyName: prodConfig.keyName,
  jenkinsInstanceType: prodConfig.jenkinsInstanceType,
  jenkinsRoleName: prodConfig.jenkinsRoleName,
  dbUsername: process.env.PROD_DB_USERNAME || '',
  dbPassword: process.env.PROD_DB_PASSWORD || '',
  dbName: 'prodappdb',
  grafanaAdminPassword: process.env.PROD_GRAFANA_ADMIN_PASSWORD || '',
  domainName: prodConfig.domainName,
  ec2InstanceType: prodConfig.instanceType.toString(),
  minInstanceCount: prodConfig.minInstanceCount,
  maxInstanceCount: prodConfig.maxInstanceCount,
  desiredInstanceCount: prodConfig.desiredInstanceCount,
  useSpotInstances: prodConfig.useSpotInstances,
  spotPrice: prodConfig.spotPrice,

  // OWASP Security settings
  blockedIpAddresses: prodConfig.blockedIpAddresses,
  maxRequestSize: prodConfig.maxRequestSize,
  requestLimit: prodConfig.requestLimit,
  enableSecurityHub: prodConfig.enableSecurityHub,

  // Stack properties
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: prodConfig.awsRegion,
  },
  description: 'ECS Jenkins with GitHub integration - Production Environment',
  tags: prodConfig.tags,
});

// Add suppressions for production stack
NagSuppressions.addStackSuppressions(prodStack, [
  { id: 'AwsSolutions-IAM4', reason: 'Using managed policies for production' },
  { id: 'AwsSolutions-IAM5', reason: 'Using wildcards in IAM policies' },
  { id: 'AwsSolutions-RDS3', reason: 'Using password authentication' },
  { id: 'AwsSolutions-EC23', reason: 'Using SSH key pairs for management' },
]);

// Disaster Recovery (DR) environment - Pilot Light in West Region
const drStack = new EcsJenkinsGithubStack(app, 'EcsJenkinsGithubDrStack', {
  awsRegion: drConfig.awsRegion, // West Coast Region for DR
  vpcCidr: drConfig.vpcCidr,
  publicSubnetCidrs: drConfig.publicSubnetCidrs,
  privateSubnetCidrs: drConfig.privateSubnetCidrs,
  databaseSubnetCidrs: drConfig.databaseSubnetCidrs,
  availabilityZones: drConfig.availabilityZones, // West coast availability zones
  environment: drConfig.environment,
  projectName: 'ecs-jenkins',
  containerPort: drConfig.containerPort,
  keyName: drConfig.keyName,
  jenkinsInstanceType: drConfig.jenkinsInstanceType, // Smaller instance for pilot light
  jenkinsRoleName: drConfig.jenkinsRoleName,
  dbUsername: process.env.DR_DB_USERNAME || '',
  dbPassword: process.env.DR_DB_PASSWORD || '',
  dbName: 'drappdb',
  grafanaAdminPassword: process.env.DR_GRAFANA_ADMIN_PASSWORD || '',
  domainName: drConfig.domainName,
  ec2InstanceType: drConfig.instanceType.toString(), // Smaller instance type for pilot light
  minInstanceCount: drConfig.minInstanceCount, // Minimal capacity for pilot light
  maxInstanceCount: drConfig.maxInstanceCount, // Can scale up if needed during DR activation
  desiredInstanceCount: drConfig.desiredInstanceCount, // Start with minimal capacity
  useSpotInstances: drConfig.useSpotInstances, // Not using spot instances for DR to ensure reliability
  spotPrice: drConfig.spotPrice,

  // OWASP Security settings
  blockedIpAddresses: drConfig.blockedIpAddresses,
  maxRequestSize: drConfig.maxRequestSize,
  requestLimit: drConfig.requestLimit,
  enableSecurityHub: drConfig.enableSecurityHub,

  // Stack properties
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: drConfig.awsRegion, // Explicitly set to west region for DR
  },
  description: 'ECS Jenkins with GitHub integration - DR Environment (Pilot Light)',
  tags: drConfig.tags,
});

// Add suppressions for DR stack
NagSuppressions.addStackSuppressions(drStack, [
  { id: 'AwsSolutions-IAM4', reason: 'Using managed policies for DR environment' },
  { id: 'AwsSolutions-IAM5', reason: 'Using wildcards in IAM policies for DR' },
  { id: 'AwsSolutions-RDS3', reason: 'Using password authentication for DR database' },
  { id: 'AwsSolutions-EC23', reason: 'Using SSH key pairs for DR instance management' },
]);
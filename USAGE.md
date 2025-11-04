# CDK Usage Guide for Terraform Users

This guide is designed specifically for developers familiar with Terraform who are transitioning to AWS CDK.

## Table of Contents
- [Conceptual Mapping](#conceptual-mapping)
- [Getting Started](#getting-started)
- [Key Differences from Terraform](#key-differences-from-terraform)
- [Common Tasks Comparison](#common-tasks-comparison)
- [CDK Commands](#cdk-commands)
- [Security and Compliance Scanning](#security-and-compliance-scanning)
- [Testing and Debugging](#testing-and-debugging)

## Conceptual Mapping

| Terraform Concept | CDK Equivalent | Description |
|-------------------|----------------|-------------|
| Provider | AWS CDK Library | The AWS CDK library offers built-in support for AWS services |
| Resource Block | Construct | CDK constructs are reusable cloud components |
| Module | Custom Construct | Create custom constructs to encapsulate related resources |
| Variables | Props | Props are passed to constructs during initialization |
| Outputs | CfnOutput | Define outputs from your stack |
| tfvars | Context Values | Context values provide configuration for different environments |
| State File | CloudFormation Stack | CDK uses CloudFormation for state management |
| Backend | CloudFormation | AWS manages the state through CloudFormation |

## Getting Started

### Prerequisites
- Node.js 14.x or later
- AWS CLI configured with appropriate credentials
- AWS CDK CLI installed (`npm install -g aws-cdk`)

### Initial Setup

1. **Install dependencies**:
   ```bash
   npm install
Build the project:
npm run build
Bootstrap CDK (only needed once per AWS account/region):
cdk bootstrap aws://ACCOUNT-NUMBER/REGION
Synthesize CloudFormation template:
npm run cdk synth
Preview changes:
npm run cdk diff
Deploy the stack:
npm run cdk deploy
CDK Commands
Here's how CDK commands map to Terraform commands:

Terraform Command	CDK Command(s)	Purpose
terraform init	npm install	Initialize the project and install dependencies
terraform validate	npm run build	Validates code syntax and structure
N/A	cdk synth	Generates CloudFormation templates without comparing to deployed state
terraform plan	cdk diff	Show what changes would be made
terraform apply	cdk deploy	Apply the infrastructure changes
terraform destroy	cdk destroy	Remove all resources defined in the stack
terraform output	cdk outputs	Show the outputs from the deployed stack
Using cdk synth
npm run cdk synth
# or
npx cdk synth
The cdk synth command:

Compiles your TypeScript code
Generates CloudFormation templates in the cdk.out directory
Validates the CDK construct structure
Shows the resulting CloudFormation YAML in the terminal
This is useful for:

Validating your infrastructure code
Inspecting the actual CloudFormation that will be deployed
Generating templates that can be checked into version control
Generating templates that can be manually deployed via CloudFormation console
Using cdk diff
npm run cdk diff
# or
npx cdk diff
The cdk diff command:

Synthesizes CloudFormation templates
Retrieves the current state of your deployed stack from AWS
Shows a diff between the local code and deployed infrastructure
Displays what resources would be created, modified, or deleted
This is the closest equivalent to terraform plan.

Common CDK Workflow
Make changes to your CDK code
Build the project: npm run build
Generate CloudFormation: npm run cdk synth
Preview changes: npm run cdk diff
Deploy changes: npm run cdk deploy
Key Differences from Terraform
Language & Flexibility:
Terraform uses HCL (HashiCorp Configuration Language)
CDK uses general-purpose programming languages (TypeScript in this project)
CDK allows for loops, conditionals, and functions directly in the language
State Management:
Terraform maintains state files that you need to manage (locally or remote)
CDK leverages CloudFormation which manages state automatically in AWS
Resource Identification:
Terraform uses resource references like aws_s3_bucket.my_bucket.id
CDK uses object-oriented approaches: const myBucket = new s3.Bucket(this, 'MyBucket');
Deployment Model:
Terraform directly makes API calls to create resources
CDK generates CloudFormation templates, which are then deployed by CloudFormation
Constructs Hierarchy:
CDK has L1 (CfnResource), L2 (curated), and L3 (patterns) constructs
No direct equivalent in Terraform, though modules are similar to L3 constructs
Common Tasks Comparison
Creating an S3 Bucket
Terraform:

resource "aws_s3_bucket" "example" {
bucket = "my-bucket"

tags = {
Name = "My bucket"
Environment = "Dev"
}
}
CDK (TypeScript):

import * as s3 from 'aws-cdk-lib/aws-s3';

// In your stack
const bucket = new s3.Bucket(this, 'MyBucket', {
bucketName: 'my-bucket',

// Tags are added as part of the props or via the tag manager
tags: {
Name: 'My bucket',
Environment: 'Dev'
}
});
Creating a VPC
Terraform:

resource "aws_vpc" "main" {
cidr_block = "10.0.0.0/16"

tags = {
Name = "MainVPC"
}
}

resource "aws_subnet" "public" {
vpc_id     = aws_vpc.main.id
cidr_block = "10.0.1.0/24"
}
CDK (TypeScript):

import * as ec2 from 'aws-cdk-lib/aws-ec2';

// In your stack
const vpc = new ec2.Vpc(this, 'MainVPC', {
cidr: '10.0.0.0/16',
natGateways: 1,
maxAzs: 2,
subnetConfiguration: [
{
name: 'public',
subnetType: ec2.SubnetType.PUBLIC,
cidrMask: 24,
},
{
name: 'private',
subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
cidrMask: 24,
}
]
});
Security and Compliance Scanning
Security Scanning in Terraform vs CDK
Terraform Tool	CDK Alternative	Description
Checkov	Manual CloudFormation scanning	Scan generated CloudFormation templates with tools like cfn_nag, CloudFormation Guard
tflint	ESLint	Use ESLint with TypeScript for code quality and security
tfsec	AWS Config Rules	Use AWS Config Rules (already in this project's security construct)
Scanning Generated CloudFormation
After running cdk synth, you can scan the generated CloudFormation templates in the cdk.out directory using:

cfn_nag:
gem install cfn-nag
cfn_nag_scan --input-path ./cdk.out/YourStackName.template.json
CloudFormation Guard:
pip install cloudformation-guard
cfn-guard validate --data ./cdk.out/YourStackName.template.json --rules your_rules.guard
Security Features Already Implemented
This project already implements several security best practices:

AWS WAF with OWASP Top 10 protections
Security groups with proper access restrictions
AWS Config Rules for compliance monitoring
GuardDuty for threat detection
CloudWatch monitoring for security events
Testing and Debugging
Testing CDK Infrastructure
Unit Testing: Test individual constructs
import { Template } from 'aws-cdk-lib/assertions';

test('VPC Created', () => {
const app = new cdk.App();
const stack = new MyStack(app, 'MyTestStack');
const template = Template.fromStack(stack);

template.hasResourceProperties('AWS::EC2::VPC', {
CidrBlock: '10.0.0.0/16'
});
});
Run tests:
npm test
Debugging
Examine CloudFormation template:
npm run cdk synth > template.yml
Debug deployment issues:
Check CloudFormation events in AWS Console
Use the --verbose flag for more details:
npm run cdk deploy -- --verbose
Check resource status:
aws cloudformation describe-stack-resources --stack-name YourStackName
Jenkins CI/CD Setup
For detailed instructions on configuring the Jenkins CI/CD pipeline included in this project, please refer to JENKINS-SETUP.md.

This guide is intended to help Terraform users transition to CDK. For more comprehensive documentation, please refer to the AWS CDK Documentation.

Remember to run npm install before attempting to run any CDK commands to ensure all dependencies are installed correctly.
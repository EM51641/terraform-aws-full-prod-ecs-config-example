# AWS Terraform Production Infrastructure

This repository contains the complete Terraform configuration for deploying a production-ready AWS infrastructure for the LiveDisplaced application.

## 🏗️ Architecture Overview

The infrastructure is designed as a modern, scalable web application with the following components:

- **Frontend**: CloudFront CDN serving static content from S3
- **Backend**: ECS Fargate containers running in private subnets
- **API**: Application Load Balancer with HTTPS termination
- **Database**: RDS PostgreSQL instance in private subnets
- **Serverless**: Lambda functions for scheduled tasks
- **Batch Processing**: AWS Batch for background jobs
- **Security**: VPC with private/public subnets, security groups, and VPC endpoints
- **Monitoring**: CloudWatch alarms and logging
- **CI/CD**: GitHub Actions integration

## 📁 Project Structure

```
aws_terraform_production_config/
├── src/
│   ├── backend/                 # Terraform state backend (S3 + DynamoDB)
│   ├── ecr_backend/            # ECR repository for container images
│   ├── environments/
│   │   └── production/         # Production environment configuration
│   │       ├── main.tf         # Main production configuration
│   │       ├── variables.tf    # Production variables
│   │       └── vpc/            # VPC configuration
│   │           ├── main.tf     # VPC resources
│   │           ├── output.tf   # VPC outputs
│   │           └── variables.tf # VPC variables
│   └── module/                 # Reusable Terraform modules
│       ├── batch/              # AWS Batch configuration
│       ├── budget/             # Cost monitoring
│       ├── ci/                 # CI/CD IAM roles
│       ├── cloudfront/         # CDN configuration
│       ├── ecs/                # ECS cluster and services
│       ├── lambda/             # Lambda functions
│       ├── lb/                 # Application Load Balancer
│       ├── rds/                # Database configuration
│       ├── route53/            # DNS and certificates
│       ├── s3/                 # S3 buckets and policies
│       ├── secret/             # Secrets Manager
│       └── ssm/                # Systems Manager
```

## 🚀 Infrastructure Components

### 1. **Networking (VPC)**
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24 (us-east-1a), 10.0.2.0/24 (us-east-1b)
- **Private Subnets**: 10.0.3.0/24 (us-east-1a), 10.0.4.0/24 (us-east-1b)
- **NAT Gateway**: For private subnet internet access
- **VPC Endpoints**: Secrets Manager, S3, ECR API/DKR, CloudWatch Logs

### 2. **Compute & Containers**
- **ECS Cluster**: Fargate-based container orchestration
- **Task Definition**: 256 CPU units, 512MB memory
- **Container Port**: 8000
- **Auto Scaling**: Enabled with deployment circuit breaker

### 3. **Database**
- **Engine**: PostgreSQL 16.3
- **Instance Class**: db.t4g.micro
- **Storage**: 20GB GP3
- **Backup Retention**: 7 days
- **Multi-AZ**: Disabled (single instance)

### 4. **Load Balancing & CDN**
- **Application Load Balancer**: HTTPS termination, HTTP to HTTPS redirect
- **Target Group**: Health checks on `/api/v1/health-check`
- **CloudFront**: Global CDN with S3 and ALB origins
- **SSL/TLS**: ACM certificates with TLS 1.2+ support

### 5. **Storage**
- **S3 Buckets**: 
  - Static content bucket
  - ALB logs bucket (7-day retention)
- **Lifecycle Policies**: Automatic cleanup of old logs

### 6. **Serverless & Batch**
- **Lambda Functions**: Scheduled tasks (30-day intervals)
- **AWS Batch**: Background job processing
- **EventBridge**: Scheduled triggers

### 7. **Security & Access**
- **Security Groups**: VPC-isolated with specific port access
- **IAM Roles**: Least privilege access for each service
- **Secrets Manager**: Application secrets and database credentials
- **VPC Endpoints**: Private AWS service access

### 8. **Monitoring & Observability**
- **CloudWatch Logs**: Centralized logging for all services
- **CloudWatch Alarms**: Service health monitoring
- **SNS Topics**: Alert notifications
- **Cost Monitoring**: Monthly budget alerts

### 9. **CI/CD Pipeline**
- **GitHub Actions**: OIDC-based authentication
- **IAM Roles**: Secure deployment permissions
- **Auto-deployment**: ECS service updates, Lambda deployments

## 🔧 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Access to AWS account with required permissions
- GitHub repository with OIDC provider configured

## 🚀 Deployment Instructions

### 1. **Initialize Backend Infrastructure**
```bash
cd src/backend
terraform init
terraform plan
terraform apply
```

### 2. **Deploy ECR Repository**
```bash
cd src/ecr_backend
terraform init
terraform plan
terraform apply
```

### 3. **Deploy Production Environment**
```bash
cd src/environments/production
terraform init
terraform plan
terraform apply
```

## 🔐 Security Features

- **VPC Isolation**: All resources run in private subnets
- **Security Groups**: Port-specific access control
- **IAM Roles**: Service-specific permissions
- **VPC Endpoints**: Private AWS service access
- **HTTPS Only**: All external traffic encrypted
- **Secrets Management**: No hardcoded credentials

## 💰 Cost Optimization

- **Fargate Spot**: 100% spot instance usage for cost savings
- **S3 Lifecycle**: Automatic cleanup of old logs
- **Budget Alerts**: 80% and 100% threshold notifications
- **Resource Tagging**: Complete cost allocation

## 📊 Monitoring & Alerts

- **ECS Service Health**: Healthy task count monitoring
- **RDS Performance**: Connection attempt monitoring
- **VPC Endpoints**: Service availability monitoring
- **Cost Alerts**: Budget threshold notifications

## 🔄 CI/CD Pipeline

The infrastructure supports automated deployments through GitHub Actions:

1. **Code Push**: Triggers deployment pipeline
2. **Security Scan**: Terraform security validation
3. **Infrastructure Update**: ECS service updates
4. **Health Check**: Service validation
5. **Rollback**: Automatic rollback on failure

## 🛠️ Module Dependencies

```
VPC → ECS → Load Balancer → CloudFront → Route53
  ↓      ↓         ↓           ↓
RDS   Lambda     S3        ACM Certificates
  ↓      ↓         ↓
Secret  Batch   VPC Endpoints
```

## 📝 Environment Variables

Key environment variables for the application:
- `DB_HOST`: RDS instance endpoint
- `DB_NAME`: Database name (postgres)
- `APP_SECRET_KEY`: Application secret key
- `FACEBOOK_CLIENT_ID/SECRET`: OAuth credentials
- `GOOGLE_CLIENT_ID/SECRET`: OAuth credentials
- `SENDGRID_API_KEY`: Email service API key

## 🚨 Important Notes

- **State Management**: Uses S3 backend with DynamoDB locking
- **Resource Protection**: Critical resources have `prevent_destroy` enabled
- **Auto Scaling**: ECS services automatically scale based on demand
- **Backup Strategy**: RDS automated backups with 7-day retention
- **SSL Certificates**: ACM certificates with automatic renewal

# AWS Infrastructure Architecture Diagram

This document contains Mermaid diagrams that visualize the complete AWS infrastructure architecture.

## 🏗️ High-Level Architecture

```mermaid
graph TB
    subgraph "Internet"
        Users[🌐 Users]
    end
    
    subgraph "AWS Cloud"
        subgraph "Edge Services"
            CF[CloudFront<br/>CDN Distribution]
            ACM[ACM Certificates<br/>SSL/TLS]
        end
        
        subgraph "Public Layer"
            ALB[Application Load Balancer<br/>HTTPS:443, HTTP:80]
            ALB_SG[ALB Security Group]
            IGW[Internet Gateway]
            NAT[NAT Gateway<br/>Elastic IP]
        end
        
        subgraph "Private Layer"
            subgraph "ECS Cluster"
                ECS[ECS Fargate Tasks<br/>Port 8000]
                ECS_SG[ECS Security Group]
            end
            
            subgraph "Database Layer"
                RDS[RDS PostgreSQL<br/>Port 5432]
                RDS_SG[RDS Security Group]
            end
            
            subgraph "Serverless"
                LAMBDA[Lambda Functions<br/>Scheduled Tasks]
                LAMBDA_SG[Lambda Security Group]
                BATCH[AWS Batch Jobs<br/>Background Processing]
                BATCH_SG[Batch Security Group]
            end
            
            subgraph "Management"
                SSM[SSM Instance<br/>Bastion Host]
                SSM_SG[SSM Security Group]
            end
        end
        
        subgraph "Storage & Services"
            S3_STATIC[S3 Static Content<br/>Website Assets]
            S3_LOGS[S3 ALB Logs<br/>7-day Retention]
            SECRETS[Secrets Manager<br/>App & DB Credentials]
        end
        
        subgraph "VPC Endpoints"
            VPCE_SM[VPC Endpoint<br/>Secrets Manager]
            VPCE_S3[VPC Endpoint<br/>S3 Gateway]
            VPCE_ECR[VPC Endpoint<br/>ECR API/DKR]
            VPCE_LOGS[VPC Endpoint<br/>CloudWatch Logs]
        end
        
        subgraph "Monitoring"
            CW_LOGS[CloudWatch Logs]
            CW_ALARMS[CloudWatch Alarms]
            SNS[SNS Topics<br/>Alert Notifications]
        end
        
        subgraph "CI/CD"
            GITHUB[GitHub Actions<br/>OIDC Provider]
            CI_ROLE[CI IAM Role<br/>Deployment Permissions]
        end
    end
    
    subgraph "DNS & Routing"
        R53[Route53<br/>livedisplaced.com]
        ECR[ECR Repository<br/>Container Images]
    end
    
    %% User traffic flow
    Users --> CF
    CDN --> CF
    CF --> ALB
    ALB --> ECS
    
    %% Internal traffic flows
    ECS --> RDS
    ECS --> S3_STATIC
    ECS --> SECRETS
    ECS --> VPCE_SM
    ECS --> VPCE_S3
    ECS --> VPCE_ECR
    ECS --> VPCE_LOGS
    
    LAMBDA --> RDS
    LAMBDA --> SECRETS
    LAMBDA --> VPCE_SM
    
    BATCH --> RDS
    BATCH --> SECRETS
    BATCH --> VPCE_SM
    
    SSM --> RDS
    
    %% Network flow
    IGW --> ALB
    IGW --> NAT
    NAT --> ECS
    NAT --> LAMBDA
    NAT --> BATCH
    NAT --> SSM
    
    %% Monitoring flow
    ECS --> CW_LOGS
    LAMBDA --> CW_LOGS
    BATCH --> CW_LOGS
    CW_LOGS --> CW_ALARMS
    CW_ALARMS --> SNS
    
    %% CI/CD flow
    GITHUB --> CI_ROLE
    CI_ROLE --> ECS
    CI_ROLE --> LAMBDA
    CI_ROLE --> BATCH
    CI_ROLE --> S3_STATIC
    
    %% DNS flow
    R53 --> CF
    R53 --> ALB
    R53 --> ACM
    
    %% Storage flow
    ALB --> S3_LOGS
    ECR --> ECS
    ECR --> LAMBDA
    ECR --> BATCH
```

## 🌐 Network Architecture

```mermaid
graph TB
    subgraph "Internet"
        INTERNET[🌐 Internet]
    end
    
    subgraph "VPC: 10.0.0.0/16"
        subgraph "Public Subnets"
            subgraph "us-east-1a"
                PUB1[Public Subnet 1<br/>10.0.1.0/24<br/>Auto-assign Public IP]
            end
            subgraph "us-east-1b"
                PUB2[Public Subnet 2<br/>10.0.2.0/24<br/>Auto-assign Public IP]
            end
        end
        
        subgraph "Private Subnets"
            subgraph "us-east-1a"
                PRIV1[Private Subnet 1<br/>10.0.3.0/24<br/>No Public IP]
            end
            subgraph "us-east-1b"
                PRIV2[Private Subnet 2<br/>10.0.4.0/24<br/>No Public IP]
            end
        end
        
        subgraph "Network Components"
            IGW[Internet Gateway]
            NAT[NAT Gateway<br/>Elastic IP]
            RT_PUB[Public Route Table<br/>0.0.0.0/0 → IGW]
            RT_PRIV[Private Route Table<br/>0.0.0.0/0 → NAT]
        end
        
        subgraph "VPC Endpoints"
            VPCE_SM[Secrets Manager<br/>Interface Endpoint]
            VPCE_S3[S3<br/>Gateway Endpoint]
            VPCE_ECR_API[ECR API<br/>Interface Endpoint]
            VPCE_ECR_DKR[ECR DKR<br/>Interface Endpoint]
            VPCE_LOGS[CloudWatch Logs<br/>Interface Endpoint]
        end
    end
    
    %% Route table associations
    RT_PUB --> PUB1
    RT_PUB --> PUB2
    RT_PRIV --> PRIV1
    RT_PRIV --> PRIV2
    
    %% Gateway connections
    INTERNET --> IGW
    IGW --> RT_PUB
    IGW --> NAT
    NAT --> RT_PRIV
    
    %% VPC endpoint placement
    VPCE_SM --> PRIV1
    VPCE_ECR_API --> PRIV1
    VPCE_ECR_DKR --> PRIV1
    VPCE_LOGS --> PRIV1
    VPCE_S3 --> RT_PRIV
```

## 🔐 Security Architecture

```mermaid
graph TB
    subgraph "Security Groups"
        subgraph "ALB Security Group"
            ALB_SG[ALB Security Group<br/>Ports: 80, 443]
            ALB_INGRESS_80[Ingress: 0.0.0.0/0:80]
            ALB_INGRESS_443[Ingress: 0.0.0.0/0:443]
            ALB_EGRESS[Egress: 0.0.0.0/0:-1]
        end
        
        subgraph "ECS Security Group"
            ECS_SG[ECS Security Group<br/>Port: 8000]
            ECS_INGRESS[Ingress: ALB SG:8000]
            ECS_EGRESS_ALB[Egress: ALB SG:8000]
            ECS_EGRESS_RDS[Egress: RDS SG:5432]
            ECS_EGRESS_VPCE[Egress: VPC CIDR:443]
            ECS_EGRESS_INTERNET[Egress: 0.0.0.0/0:443]
        end
        
        subgraph "RDS Security Group"
            RDS_SG[RDS Security Group<br/>Port: 5432]
            RDS_INGRESS_ECS[Ingress: ECS SG:5432]
            RDS_INGRESS_LAMBDA[Ingress: Lambda SG:5432]
            RDS_INGRESS_BATCH[Ingress: Batch SG:5432]
            RDS_INGRESS_SSM[Ingress: SSM SG:5432]
            RDS_EGRESS[Egress: ECS SG:-1]
        end
        
        subgraph "Lambda Security Group"
            LAMBDA_SG[Lambda Security Group]
            LAMBDA_EGRESS_RDS[Egress: RDS SG:5432]
            LAMBDA_EGRESS_VPCE[Egress: 0.0.0.0/0:443]
        end
        
        subgraph "Batch Security Group"
            BATCH_SG[Batch Security Group]
            BATCH_EGRESS_RDS[Egress: RDS SG:5432]
            BATCH_EGRESS_VPCE[Egress: 0.0.0.0/0:443]
        end
        
        subgraph "SSM Security Group"
            SSM_SG[SSM Security Group]
            SSM_EGRESS_RDS[Egress: RDS SG:5432]
            SSM_EGRESS_HTTPS[Egress: 0.0.0.0/0:443]
        end
        
        subgraph "VPC Endpoints Security Group"
            VPCE_SG[VPC Endpoints Security Group]
            VPCE_INGRESS_ECS[Ingress: ECS SG:443]
            VPCE_INGRESS_LAMBDA[Ingress: Lambda SG:443]
            VPCE_EGRESS[Egress: 0.0.0.0/0:-1]
        end
    end
    
    %% Security group connections
    ALB_SG --> ALB_INGRESS_80
    ALB_SG --> ALB_INGRESS_443
    ALB_SG --> ALB_EGRESS
    
    ECS_SG --> ECS_INGRESS
    ECS_SG --> ECS_EGRESS_ALB
    ECS_SG --> ECS_EGRESS_RDS
    ECS_SG --> ECS_EGRESS_VPCE
    ECS_SG --> ECS_EGRESS_INTERNET
    
    RDS_SG --> RDS_INGRESS_ECS
    RDS_SG --> RDS_INGRESS_LAMBDA
    RDS_SG --> RDS_INGRESS_BATCH
    RDS_SG --> RDS_INGRESS_SSM
    RDS_SG --> RDS_EGRESS
    
    LAMBDA_SG --> LAMBDA_EGRESS_RDS
    LAMBDA_SG --> LAMBDA_EGRESS_VPCE
    
    BATCH_SG --> BATCH_EGRESS_RDS
    BATCH_SG --> BATCH_EGRESS_VPCE
    
    SSM_SG --> SSM_EGRESS_RDS
    SSM_SG --> SSM_EGRESS_HTTPS
    
    VPCE_SG --> VPCE_INGRESS_ECS
    VPCE_SG --> VPCE_INGRESS_LAMBDA
    VPCE_SG --> VPCE_EGRESS
```

## 🔄 Data Flow Architecture

```mermaid
sequenceDiagram
    participant User as 🌐 User
    participant CF as CloudFront
    participant ALB as Load Balancer
    participant ECS as ECS Tasks
    participant RDS as RDS Database
    participant S3 as S3 Buckets
    participant Lambda as Lambda Functions
    participant Batch as AWS Batch
    participant VPCE as VPC Endpoints
    
    %% User request flow
    User->>CF: HTTPS Request
    CF->>ALB: Forward Request
    ALB->>ECS: Route to Healthy Task
    
    %% Application processing
    ECS->>RDS: Database Query
    RDS-->>ECS: Query Results
    ECS->>S3: Static Asset Request
    S3-->>ECS: Asset Response
    ECS->>VPCE: AWS Service Call
    VPCE-->>ECS: Service Response
    
    %% Response flow
    ECS-->>ALB: Application Response
    ALB-->>CF: HTTP Response
    CF-->>User: Cached/Origin Response
    
    %% Background processing
    Note over Lambda,Batch: Scheduled Tasks
    Lambda->>RDS: Background Database Operations
    Lambda->>VPCE: AWS Service Calls
    Batch->>RDS: Batch Processing
    Batch->>VPCE: AWS Service Calls
```

## 📊 Monitoring & Alerting Architecture

```mermaid
graph TB
    subgraph "AWS Services"
        ECS[ECS Service]
        RDS[RDS Database]
        VPCE[VPC Endpoints]
        ALB[Load Balancer]
    end
    
    subgraph "CloudWatch"
        METRICS[CloudWatch Metrics]
        LOGS[CloudWatch Logs]
        ALARMS[CloudWatch Alarms]
    end
    
    subgraph "Notifications"
        SNS[SNS Topics]
        EMAIL[Email Alerts]
    end
    
    subgraph "Budget Monitoring"
        BUDGET[Cost Budget]
        BUDGET_ALERMS[Budget Alarms]
    end
    
    %% Data collection
    ECS --> METRICS
    ECS --> LOGS
    RDS --> METRICS
    RDS --> LOGS
    VPCE --> METRICS
    ALB --> METRICS
    ALB --> LOGS
    
    %% Alerting
    METRICS --> ALARMS
    ALARMS --> SNS
    SNS --> EMAIL
    
    %% Budget monitoring
    BUDGET --> BUDGET_ALERMS
    BUDGET_ALERMS --> SNS
```

## 🔧 Infrastructure as Code Structure

```mermaid
graph TB
    subgraph "Terraform Configuration"
        subgraph "Root Level"
            PROD_MAIN[Production main.tf]
            PROD_VARS[Production variables.tf]
        end
        
        subgraph "VPC Module"
            VPC_MAIN[VPC main.tf]
            VPC_OUTPUTS[VPC outputs.tf]
            VPC_VARS[VPC variables.tf]
        end
        
        subgraph "Service Modules"
            ECS_MOD[ECS Module]
            LAMBDA_MOD[Lambda Module]
            RDS_MOD[RDS Module]
            LB_MOD[Load Balancer Module]
            S3_MOD[S3 Module]
            CF_MOD[CloudFront Module]
            R53_MOD[Route53 Module]
            BATCH_MOD[Batch Module]
            CI_MOD[CI Module]
            SECRET_MOD[Secret Module]
            SSM_MOD[SSM Module]
            BUDGET_MOD[Budget Module]
        end
        
        subgraph "Backend"
            BACKEND[Backend Configuration]
            ECR_BACKEND[ECR Backend]
        end
    end
    
    %% Dependencies
    PROD_MAIN --> VPC_MAIN
    PROD_MAIN --> ECS_MOD
    PROD_MAIN --> LAMBDA_MOD
    PROD_MAIN --> RDS_MOD
    PROD_MAIN --> LB_MOD
    PROD_MAIN --> S3_MOD
    PROD_MAIN --> CF_MOD
    PROD_MAIN --> R53_MOD
    PROD_MAIN --> BATCH_MOD
    PROD_MAIN --> CI_MOD
    PROD_MAIN --> SECRET_MOD
    PROD_MAIN --> SSM_MOD
    PROD_MAIN --> BUDGET_MOD
    
    %% Module dependencies
    ECS_MOD --> VPC_OUTPUTS
    LAMBDA_MOD --> VPC_OUTPUTS
    RDS_MOD --> VPC_OUTPUTS
    LB_MOD --> VPC_OUTPUTS
    S3_MOD --> CF_MOD
    CF_MOD --> R53_MOD
    CI_MOD --> ECS_MOD
    CI_MOD --> LAMBDA_MOD
    CI_MOD --> BATCH_MOD
    CI_MOD --> S3_MOD
```

---

## 📋 Diagram Legend

- **🟢 Green**: Public/Internet-facing resources
- **🔴 Red**: Private/internal resources  
- **🔵 Blue**: Security and networking components
- **🟡 Yellow**: Storage and data services
- **🟠 Orange**: Compute and application services
- **🟣 Purple**: Monitoring and management services

## 🔍 How to Use These Diagrams

1. **High-Level Architecture**: Use for stakeholder presentations and overview
2. **Network Architecture**: Use for network design reviews and troubleshooting
3. **Security Architecture**: Use for security audits and compliance reviews
4. **Data Flow**: Use for understanding application behavior and performance
5. **CI/CD Pipeline**: Use for deployment process documentation
6. **Monitoring**: Use for observability and alerting setup
7. **Infrastructure as Code**: Use for development and maintenance planning

These diagrams are automatically generated from the Terraform configuration and provide a comprehensive view of your AWS infrastructure architecture.

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-public-subnet-1"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-public-subnet-2"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-private-subnet-1"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-private-subnet-2"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-igw"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
vpc_id = aws_vpc.main.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.main.id
}

tags = {
Name        = "${var.project_name}-${var.env_name}-vpc-public-rt"
Environment = var.env_name
Project     = var.project_name
}
}

resource "aws_route_table" "private" {
vpc_id = aws_vpc.main.id

tags = {
Name        = "${var.project_name}-${var.env_name}-vpc-private-rt"
Environment = var.env_name
Project     = "${var.project_name}"
}
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public" {
subnet_id      = aws_subnet.public.id
route_table_id = aws_route_table.public.id
}

# Route Table Association for Public Subnet 2
resource "aws_route_table_association" "public_2" {
subnet_id      = aws_subnet.public_2.id
route_table_id = aws_route_table.public.id
}

# Route Table Association for Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Route Table Association for Private Subnet 2
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
name        = "${var.project_name}-${var.env_name}-vpc-endpoints-sg"
description = "Security group for VPC endpoints"
vpc_id      = aws_vpc.main.id

tags = {
Name        = "${var.project_name}-${var.env_name}-vpc-endpoints-sg"
Environment = var.env_name
Project     = var.project_name
}
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-${var.env_name}-nat-eip"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "${var.project_name}-${var.env_name}-nat-gateway"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Add route to private route table for internet access via NAT Gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# VPC Endpoints for AWS Services
 resource "aws_vpc_endpoint" "secretsmanager" {
   vpc_id              = aws_vpc.main.id
   service_name        = "com.amazonaws.us-east-1.secretsmanager"
   vpc_endpoint_type   = "Interface"
   subnet_ids          = [aws_subnet.private.id]
   private_dns_enabled = true
   security_group_ids  = [aws_security_group.vpc_endpoints.id]
 
   tags = {
     Name        = "${var.project_name}-${var.env_name}-secretsmanager-endpoint"
     Environment = var.env_name
     Project     = var.project_name
   }
 }
 
 # VPC Endpoints for S3
 resource "aws_vpc_endpoint" "s3" {
   vpc_id            = aws_vpc.main.id
   service_name      = "com.amazonaws.us-east-1.s3"
   vpc_endpoint_type = "Gateway"
   route_table_ids   = [aws_route_table.private.id]
 
   tags = {
     Name        = "${var.project_name}-${var.env_name}-s3-endpoint"
     Environment = var.env_name
     Project     = var.project_name
   }
 }
 
 # VPC Endpoints for ECR API
 resource "aws_vpc_endpoint" "ecr_api" {
   vpc_id              = aws_vpc.main.id
   service_name        = "com.amazonaws.us-east-1.ecr.api"
   vpc_endpoint_type   = "Interface"
   subnet_ids          = [aws_subnet.private.id]
   private_dns_enabled = true
   security_group_ids  = [aws_security_group.vpc_endpoints.id]
 
   tags = {
     Name        = "${var.project_name}-${var.env_name}-ecr-api-endpoint"
     Environment = var.env_name
     Project     = var.project_name
   }
 }
 
 # VPC Endpoints for ECR DKR
 resource "aws_vpc_endpoint" "ecr_dkr" {
   vpc_id              = aws_vpc.main.id
   service_name        = "com.amazonaws.us-east-1.ecr.dkr"
   vpc_endpoint_type   = "Interface"
   subnet_ids          = [aws_subnet.private.id]
   private_dns_enabled = true
   security_group_ids  = [aws_security_group.vpc_endpoints.id]
 
   tags = {
     Name        = "${var.project_name}-${var.env_name}-ecr-dkr-endpoint"
     Environment = var.env_name
     Project     = var.project_name
   }
 }
 
 # VPC Endpoints for CloudWatch Logs
 resource "aws_vpc_endpoint" "logs" {
   vpc_id              = aws_vpc.main.id
   service_name        = "com.amazonaws.us-east-1.logs"
   vpc_endpoint_type   = "Interface"
   subnet_ids          = [aws_subnet.private.id]
   private_dns_enabled = true
   security_group_ids  = [aws_security_group.vpc_endpoints.id]
 
   tags = {
     Name        = "${var.project_name}-${var.env_name}-logs-endpoint"
     Environment = var.env_name
     Project     = var.project_name
   }
 }

# Ingress rule for the application security group
resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_ingress" {
  description                  = "Allow HTTPS from ECS tasks"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = var.ecs_security_group_id

  lifecycle {
    precondition {
      condition     = var.ecs_security_group_id != null
      error_message = "ECS Security Group ID is required"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-endpoints-ingress"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Ingress rule for the lambda security group
resource "aws_vpc_security_group_ingress_rule" "vpc_security_group_lambda_ingress" {
  description                  = "Allow HTTPS from lambda functions"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = var.lambda_security_group_id

  lifecycle {
    precondition {
      condition     = var.lambda_security_group_id != null
      error_message = "Lambda Security Group ID is required"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-vpc-lambda-ingress-port-443"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Egress rule for the application security group
resource "aws_vpc_security_group_egress_rule" "vpc_endpoints_egress" {
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.vpc_endpoints.id
  cidr_ipv4         = "0.0.0.0/0"
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.env_name}-alarms"

  tags = {
    Name        = "${var.project_name}-${var.env_name}-alarms"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Alarm for Secrets Manager VPC Endpoint
 resource "aws_cloudwatch_metric_alarm" "secretsmanager_endpoint" {
   alarm_name          = "${var.project_name}-${var.env_name}-secretsmanager-endpoint-alarm"
   comparison_operator = "GreaterThanThreshold"
   evaluation_periods  = "2"
   metric_name         = "ConnectionAttemptCount"
   namespace           = "AWS/VpcEndpoints"
   period              = "300"
   statistic           = "Sum"
   threshold           = "100"
   alarm_description   = "This metric monitors Secrets Manager VPC endpoint connection attempts"
 
   dimensions = {
     VpcEndpointId = aws_vpc_endpoint.secretsmanager.id
   }
 
   alarm_actions = [aws_sns_topic.alarms.arn]
   ok_actions    = [aws_sns_topic.alarms.arn]
 
   tags = {
     Name        = "${var.project_name}-${var.env_name}-secretsmanager-endpoint-alarm"
     Environment = var.env_name
     Project     = var.project_name
   }
 }

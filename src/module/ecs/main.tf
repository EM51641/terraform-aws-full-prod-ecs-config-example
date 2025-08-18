# Get the current version of the RDS secret
data "aws_secretsmanager_secret_version" "rds_current" {
  secret_id = var.rds_secret_arn
}

# Security Group for the tasks
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.env_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-sg"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Ingress rule for the application security group
resource "aws_vpc_security_group_ingress_rule" "http_ingress" {
  description                  = "Allow inbound HTTP from ALB"
  security_group_id            = aws_security_group.ecs_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = var.lb_security_group_id
}

# Egress rule for the application security group
resource "aws_vpc_security_group_egress_rule" "main_egress" {
  description                  = "Allow outbound traffic to the application security group"
  security_group_id            = aws_security_group.ecs_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = var.lb_security_group_id
}

# Egress for AWS Services via VPC Endpoints
resource "aws_vpc_security_group_egress_rule" "vpc_endpoints" {
  description       = "Allow HTTPS to VPC Endpoints"
  security_group_id = aws_security_group.ecs_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr_block
}


# Egress for AWS Services via VPC Endpoints
resource "aws_vpc_security_group_egress_rule" "vpc_endpoints_2" {
  description       = "Allow HTTPS to VPC Endpoints"
  security_group_id = aws_security_group.ecs_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Egress for RDS
resource "aws_vpc_security_group_egress_rule" "rds" {
  description                  = "Allow PostgreSQL to RDS"
  security_group_id            = aws_security_group.ecs_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.rds_security_group_id
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_cluster_logs" {
  name = "ecs/${var.project_name}/${var.env_name}"
  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-cluster-logs"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.env_name}-ecs-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cluster_logs.name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-cluster"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# ECS Capacity Provider
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }
}

# Service Role Trust Policy
data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Service Role - Permissions the service can use during execution
data "aws_iam_policy_document" "ecs_service_role_permissions" {

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "*",
      "${aws_cloudwatch_log_group.ecs_cluster_logs.arn}",
      "${aws_cloudwatch_log_group.ecs_cluster_logs.arn}:*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.secrets_manager_arn, var.rds_secret_arn]
  }
}

# Service Role - Execution Role
resource "aws_iam_role" "ecs_service_execution_role" {
  name               = "${var.project_name}-${var.env_name}-ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role_policy.json

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-service-role"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

resource "aws_iam_role_policy" "ecs_service_execution_role_permissions" {
  name   = "${var.project_name}-${var.env_name}-ecs-service-role-permissions"
  role   = aws_iam_role.ecs_service_execution_role.id
  policy = data.aws_iam_policy_document.ecs_service_role_permissions.json
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                               = "${var.project_name}-${var.env_name}-ecs-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = "${var.project_name}-${var.env_name}-ecs-task"
    container_port   = 8000
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false # Set to false if using private subnets
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true # Auto rollback if deployment fails
  }

  triggers = {
    secrets_manager_arn = data.aws_secretsmanager_secret_version.rds_current.arn
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      tags
    ]
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-service"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Task Role Trust Policy
data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 2. S3 and CloudWatch Permissions (What they can do)
data "aws_iam_policy_document" "task_permissions" {
  # S3 permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      var.s3_static_bucket_arn
    ]
  }

  # CloudWatch permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "${aws_cloudwatch_log_group.ecs_cluster_logs.arn}:*"
    ]
  }
}

# Task Role - Permissions the container can use during execution
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-${var.env_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_policy.json

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-task-role"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Attach the policy to the task role
resource "aws_iam_role_policy" "task_permissions" {
  name   = "${var.project_name}-${var.env_name}-ecs-task-role-permissions"
  role   = aws_iam_role.ecs_task_role.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

# Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.env_name}-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_service_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.env_name}-ecs-task"
      image     = "010526276787.dkr.ecr.us-east-1.amazonaws.com/livedisplaced-global-ecr:production-12c6d3e"
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.ecs_cluster_logs.name}"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "${var.project_name}-${var.env_name}-ecs-task"
        }
      }
      environment = [
        {
          name  = "DB_HOST"
          value = var.rds_host
        },
        {
          name  = "DB_NAME"
          value = "postgres"
        }
      ]
      secrets = [
        {
          name      = "APP_SECRET_KEY"
          valueFrom = "${var.app_secret_arn}:secret-key::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.rds_secret_arn}:password::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.rds_secret_arn}:username::"
        },
        {
          name      = "FACEBOOK_CLIENT_ID"
          valueFrom = "${var.app_secret_arn}:facebook-client-id::"
        },
        {
          name      = "FACEBOOK_CLIENT_SECRET"
          valueFrom = "${var.app_secret_arn}:facebook-client-secret::"
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = "${var.app_secret_arn}:google-client-id::"
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = "${var.app_secret_arn}:google-client-secret::"
        },
        {
          name      = "SENDGRID_API_KEY"
          valueFrom = "${var.app_secret_arn}:sendgrid-api-key::"
        }
      ],
    }
  ])

  lifecycle {
    ignore_changes = [
      container_definitions,
      tags
    ]
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ecs-task"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Add CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "service_health" {
  alarm_name          = "${var.project_name}-${var.env_name}-service-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyTaskCount"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ECS service health"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

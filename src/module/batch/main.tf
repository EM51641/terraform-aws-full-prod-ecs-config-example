# cloudwatch log group
resource "aws_cloudwatch_log_group" "batch_logs" {
  name              = "/aws/batch/${var.project_name}-${var.env_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.env_name}-batch-logs"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

resource "aws_batch_compute_environment" "main" {
  compute_environment_name = "${var.project_name}-${var.env_name}-batch-compute-environment"

  compute_resources {
    max_vcpus = var.max_vcpus
    min_vcpus = 0

    security_group_ids = [
      aws_security_group.batch.id
    ]

    subnets = var.subnets

    type = "FARGATE"
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws_batch_service_role]

  tags = {
    Name        = "${var.project_name}-${var.env_name}-batch-compute-environment"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# batch compute environment
resource "aws_security_group" "batch" {
  name        = "${var.project_name}-${var.env_name}-batch-sg"
  description = "Security group for batch"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${var.project_name}-${var.env_name}-batch-sg"
    Environment = var.env_name
    Project     = var.project_name
  }
}

resource "aws_vpc_security_group_egress_rule" "secrets_manager" {
  description       = "Allow HTTPS to Secrets Manager"
  security_group_id = aws_security_group.batch.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Security group for RDS access
resource "aws_vpc_security_group_egress_rule" "rds" {
  description                  = "Allow PostgreSQL to RDS"
  security_group_id            = aws_security_group.batch.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.rds_security_group_id
}

# batch service role
data "aws_iam_policy_document" "aws_batch_service_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }
  }
}

# batch service role
resource "aws_iam_role" "aws_batch_service_role" {
  name               = "${var.project_name}-${var.env_name}-batch-service-role"
  assume_role_policy = data.aws_iam_policy_document.aws_batch_service_role.json
}

# batch service role policy   
resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}


# ecs task role policy
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

# ecs task role
resource "aws_iam_role" "batch_ecs_task_role" {
  name               = "${var.project_name}-${var.env_name}-batch-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_policy.json

  tags = {
    Name        = "${var.project_name}-${var.env_name}-batch-ecs-task-role"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# batch role policy
data "aws_iam_policy_document" "batch_ecs_task_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      var.rds_secret_arn,
    ]
  }

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
      "ecr:BatchGetImage"
    ]
    resources = [
      var.ecr_repository_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "${aws_cloudwatch_log_group.batch_logs.arn}",
      "${aws_cloudwatch_log_group.batch_logs.arn}:log-stream:*"
    ]
  }
}

# Create the policy
resource "aws_iam_policy" "batch_ecs_task_role_policy" {
  name        = "${var.project_name}-${var.env_name}-batch-ecs-task-role-policy"
  description = "Policy for batch ecs task role"
  policy      = data.aws_iam_policy_document.batch_ecs_task_role_policy.json
}

# Attach the policy
resource "aws_iam_role_policy_attachment" "batch_ecs_task_role" {
  role       = aws_iam_role.batch_ecs_task_role.name
  policy_arn = aws_iam_policy.batch_ecs_task_role_policy.arn
}

# task execution role
data "aws_iam_policy_document" "batch_task_execution_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# task execution role
resource "aws_iam_role" "batch_task_execution_role" {
  name               = "${var.project_name}-${var.env_name}-batch-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.batch_task_execution_role.json
}

# Add policy for task execution role
data "aws_iam_policy_document" "batch_task_execution_policy" {

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [
      var.ecr_repository_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "${aws_cloudwatch_log_group.batch_logs.arn}",
      "${aws_cloudwatch_log_group.batch_logs.arn}:log-stream:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      var.rds_secret_arn,
      var.app_secret_arn
    ]
  }
}

# task execution role policy
resource "aws_iam_role_policy" "batch_task_execution_policy" {
  name   = "${var.project_name}-${var.env_name}-batch-task-execution-policy"
  role   = aws_iam_role.batch_task_execution_role.id
  policy = data.aws_iam_policy_document.batch_task_execution_policy.json
}

# job definition
resource "aws_batch_job_definition" "job" {
  name                  = "${var.project_name}-${var.env_name}-batch-task"
  type                  = "container"
  platform_capabilities = ["FARGATE"]

  ecs_properties = jsonencode({
    taskProperties = [{
      executionRoleArn = aws_iam_role.batch_task_execution_role.arn
      taskRoleArn      = aws_iam_role.batch_ecs_task_role.arn
      containers = [
        {
          name  = "${var.project_name}-${var.env_name}-batch-task"
          image = "${var.image}:latest"
          resourceRequirements = [
            {
              type  = "VCPU"
              value = var.task_cpu
            },
            {
              type  = "MEMORY"
              value = var.task_memory
            }
          ]

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
              "awslogs-group"         = "${aws_cloudwatch_log_group.batch_logs.name}"
              "awslogs-region"        = var.region
              "awslogs-stream-prefix" = "${var.project_name}-${var.env_name}-batch-task"
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
          ]
        }
      ]
    }]
  })

  lifecycle {
    ignore_changes = [
      ecs_properties
    ]
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-batch-ecs-task"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}


# job queue
resource "aws_batch_job_queue" "main" {
  name     = "${var.project_name}-${var.env_name}-job-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    compute_environment = aws_batch_compute_environment.main.arn
    order               = 1
  }
}

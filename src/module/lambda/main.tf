locals {
  function_name = "${var.project_name}-${var.env_name}-scheduled-lambda"
  role_name     = "${var.project_name}-${var.env_name}-lambda-role"
}

# Assume role policy
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Lambda role and policies
resource "aws_iam_role" "lambda_role" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = {
    Name        = local.role_name
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Lambda Role Policy
data "aws_iam_policy_document" "lambda_role_policy" {
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
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.lambda_logs.arn}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

# Lambda execution policy
resource "aws_iam_role_policy" "lambda_execution_policy" {
  name   = "${local.role_name}-execution-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_role_policy.json
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "/aws/lambda/${local.function_name}"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-${var.env_name}-lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${var.project_name}-${var.env_name}-lambda-sg"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}
###

# Egress rule for PostgreSQL connection to the RDS
resource "aws_vpc_security_group_egress_rule" "lambda_egress" {
  description                  = "Allow outbound traffic to the application security group"
  security_group_id            = aws_security_group.lambda_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.rds_security_group_id
}
###

# Egress rule for VPC Endpoints
resource "aws_vpc_security_group_egress_rule" "lambda_vpc_endpoints_egress" {
  description       = "Allow HTTPS to VPC Endpoints"
  security_group_id = aws_security_group.lambda_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Lambda function
resource "aws_lambda_function" "scheduled_lambda" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  architectures = ["arm64"]

  memory_size = 1024
  timeout     = 300

  lifecycle {
    ignore_changes = [
      image_uri,
      environment
    ]
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name        = local.function_name
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# EventBridge rule
resource "aws_cloudwatch_event_rule" "weekly_trigger" {
  name                = "${local.function_name}-trigger"
  description         = "Triggers lambda function weekly"
  schedule_expression = "rate(30 days)"

  tags = {
    Name        = "${local.function_name}-trigger"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_trigger.name
  target_id = "${local.function_name}-target"
  arn       = aws_lambda_function.scheduled_lambda.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_trigger.arn
}

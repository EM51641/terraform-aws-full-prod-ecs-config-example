# Application Load Balancer
resource "aws_lb" "main" {
  name                       = "${var.project_name}-${var.env_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = var.public_subnets_ids
  enable_deletion_protection = true

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name
    ]
  }

  access_logs {
    bucket  = var.s3_bucket_lb_logs_id
    prefix  = "alb-logs/${var.env_name}"
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-alb"
    Environment = var.env_name
    Project     = var.project_name
  }
}

data "aws_iam_policy_document" "lb_logs" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"] # AWS ELB account ID for us-east-1
    }
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_lb_logs_arn}/*"]
  }
}

# Allow ALB to write to the S3 bucket
resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = var.s3_bucket_lb_logs_id
  policy = data.aws_iam_policy_document.lb_logs.json

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.env_name}-alb-tg-v1"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/api/v1/health-check" # Change this to match your application's health check endpoint
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399" # Accept any 2XX or 3XX response as healthy
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for ALB
resource "aws_security_group" "lb_sg" {
  name        = "${var.project_name}-${var.env_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${var.project_name}-${var.env_name}-alb-sg"
    Environment = var.env_name
    Project     = var.project_name
  }
}
###

# Ingress rule for ALB
resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  description       = "Allow inbound traffic from the application security group"
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http" {
  description       = "Allow inbound HTTP traffic"
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}
###

# Egress rule for ALB
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  description       = "Allow outbound traffic to the application security group"
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
###

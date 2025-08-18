data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-${var.env_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.env_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "ssm_instance" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type          = "t4g.nano"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ssm-instance"
    Environment = var.env_name
    Project     = var.project_name
  }
}

resource "aws_security_group" "ssm_sg" {
  name        = "${var.project_name}-${var.env_name}-ssm-sg"
  description = "Security group for SSM instance"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.env_name}-ssm-sg"
    Environment = var.env_name
    Project     = var.project_name
  }
}

resource "aws_vpc_security_group_egress_rule" "ssm_rds_egress" {
  security_group_id            = aws_security_group.ssm_sg.id
  description                  = "Allow PostgreSQL to RDS"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.rds_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "ssm_https_egress" {
  security_group_id = aws_security_group.ssm_sg.id
  description       = "Allow HTTPS outbound"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

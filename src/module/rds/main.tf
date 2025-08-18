# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.env_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${var.project_name}-${var.env_name}-rds-sg"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}
###

# Ingress rule for PostgreSQL connection from the application
resource "aws_vpc_security_group_ingress_rule" "rds_ingress" {
  description                  = "Allow inbound traffic from the application security group"
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.app_security_group_id
}
###

# Ingress rule for PostgreSQL connection from the lambda
resource "aws_vpc_security_group_ingress_rule" "rds_ingress_lambda" {
  description                  = "Allow inbound traffic from the lambda security group"
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.lambda_security_group_id
}
###

# Ingress rule for PostgreSQL from the SSM client
resource "aws_vpc_security_group_ingress_rule" "rds_ingress_ssm" {
  description                  = "Allow inbound traffic from the SSM instance security group"
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.ssm_security_group_id
}
###

# Ingress rule for PostgreSQL from the batch
resource "aws_vpc_security_group_ingress_rule" "rds_ingress_batch" {
  description                  = "Allow inbound traffic from the batch security group"
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.batch_security_group_id
}
###

# Egress rule
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  description                  = "Allow outbound traffic to the application security group"
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "-1"
  referenced_security_group_id = var.app_security_group_id
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.env_name}-rds-subnet-group"
  subnet_ids = var.subnet_ids # Add this variable

  tags = {
    Name        = "${var.project_name}-${var.env_name}-rds-subnet-group"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# RDS Instance
resource "aws_db_instance" "main_db" {
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = var.instance_class
  identifier           = "${var.project_name}-${var.env_name}-rds-db"
  db_name              = "postgres"
  username             = "postgres"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = 7
  multi_az                = false
  publicly_accessible     = false

  manage_master_user_password = true

  allocated_storage = 20
  storage_type      = "gp3"

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      backup_window,
      maintenance_window,
      snapshot_identifier,
      master_user_secret,
    ]
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-rds-db"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

resource "aws_secretsmanager_secret_rotation" "rds_master" {
  secret_id = aws_db_instance.main_db.master_user_secret[0].secret_arn

  rotation_rules {
    automatically_after_days = 365
  }
}

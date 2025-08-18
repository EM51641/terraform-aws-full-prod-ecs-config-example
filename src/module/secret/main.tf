# Secrets Manager for the application
resource "aws_secretsmanager_secret" "app" {
  name = "${var.project_name}-${var.env_name}-secret-v1"

  lifecycle {
    prevent_destroy = true # Prevent accidental deletion
  }

  tags = {
    Name        = "${var.project_name}-${var.env_name}-secret"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

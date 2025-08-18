output "app_secret_arn" {
  description = "The ARN of the secret"
  value       = aws_secretsmanager_secret.app.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main_db.endpoint
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main_db.arn
}

output "db_security_group_id" {
  description = "The ID of the security group attached to the RDS instance"
  value       = aws_security_group.rds_sg.id
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = aws_db_instance.main_db.identifier
}

output "rds_host" {
  description = "The host of the RDS instance"
  value       = aws_db_instance.main_db.endpoint
}

output "rds_secret_arn" {
  description = "The ARN of the RDS secret"
  value       = aws_db_instance.main_db.master_user_secret[0].secret_arn
}

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.main_db.id
}

output "ssm_security_group_id" {
  description = "The ARN of the ALB"
  value       = aws_security_group.ssm_sg.id
}

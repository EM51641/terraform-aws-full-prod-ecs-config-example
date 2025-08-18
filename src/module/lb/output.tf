output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.main.arn
}

output "lb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.lb_sg.id
}

output "lb_target_group_arn" {
  description = "The ARN of the ALB target group"
  value       = aws_lb_target_group.main.arn
}

output "lb_listener_arn" {
  description = "The ARN of the ALB listener"
  value       = aws_lb_listener.https.arn
}

output "alb_domain_name" {
  description = "The domain name of the ALB"
  value       = aws_lb.main.dns_name
}

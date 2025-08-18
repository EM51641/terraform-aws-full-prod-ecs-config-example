output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "service_arn" {
  description = "The ARN of the ECS service"
  value       = aws_ecs_service.main.id
}

output "ecs_family" {
  description = "The family of the ECS task definition"
  value       = aws_ecs_task_definition.main.family
}

output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_service_execution_role.arn
}

output "task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs_cluster_logs.name
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.ecs_sg.id
}

output "task_cpu" {
  description = "The number of CPU units (in vCPUs)"
  value       = aws_ecs_task_definition.main.cpu
}

output "task_memory" {
  description = "The number of memory units (in MB)"
  value       = aws_ecs_task_definition.main.memory
}

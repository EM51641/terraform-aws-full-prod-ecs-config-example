output "batch_security_group_id" {
  value = aws_security_group.batch.id
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.batch_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.batch_ecs_task_role.arn
}

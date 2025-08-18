output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.scheduled_lambda.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.scheduled_lambda.function_name
}

output "eventbridge_rule_arn" {
  description = "The ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.weekly_trigger.arn
}

output "lambda_security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.lambda_sg.id
}
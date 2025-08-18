variable "project_name" {
  description = "The project name"
  type        = string
}

variable "env_name" {
  description = "The environment name"
  type        = string
}

variable "github_org" {
  description = "The GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository name"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "github_branch" {
  description = "The branch to run the CI/CD pipeline on"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "The ARN of the ECS execution role"
  type        = string
}

variable "ecs_family" {
  description = "The family of the ECS task definition"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "service_arn" {
  description = "The ARN of the ECS service"
  type        = string
}

variable "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  type        = string
}

variable "ecs_task_cpu" {
  description = "The number of CPU units (in vCPUs)"
  type        = number
}

variable "ecs_task_memory" {
  description = "The number of memory units (in MB)"
  type        = number
}

variable "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  type        = string
}

variable "batch_ecs_task_execution_role_arn" {
  description = "The ARN of the Batch ECS task execution role"
  type        = string
}

variable "batch_ecs_task_role_arn" {
  description = "The ARN of the Batch ECS task role"
  type        = string
}



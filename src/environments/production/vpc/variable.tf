variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ECS security group ID"
  type        = string
  default     = null
}

variable "lambda_security_group_id" {
  description = "Lambda security group ID"
  type        = string
  default     = null
}

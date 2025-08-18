variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "instance_class" {
  description = "Instance class"
  type        = string
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "lambda_security_group_id" {
  description = "ID of the lambda security group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS"
  type        = list(string)
}

variable "ssm_security_group_id" {
  description = "SSM security group ID"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "batch_security_group_id" {
  description = "Batch security group ID"
  type        = string
}

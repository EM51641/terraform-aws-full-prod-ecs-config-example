variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "s3_static_bucket_arn" {
  description = "ARN of the S3 bucket for static assets"
  type        = string
}

variable "secrets_manager_arn" {
  description = "ARN of the Secrets Manager"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the subnets"
  type        = list(string)
}

variable "lb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "lb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "rds_host" {
  description = "The host of the RDS instance"
  type        = string
}

variable "rds_secret_arn" {
  description = "The ARN of the RDS secret"
  type        = string
}

variable "rds_security_group_id" {
  description = "ID of the RDS security group"
  type        = string
}

variable "app_secret_arn" {
  description = "The ARN of the secret"
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
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

variable "region" {
  description = "AWS region"
  type        = string
}

variable "task_cpu" {
  description = "The number of CPU units (in vCPUs)"
  type        = number
}

variable "task_memory" {
  description = "The number of memory units (in MB)"
  type        = number
}

variable "lambda_image_uri" {
  description = "Initial Lambda container image URI"
  type        = string
  default     = "010526276787.dkr.ecr.us-east-1.amazonaws.com/livedisplaced-global-ecr:latest"
}

variable "ecr_repository_arn" {
  description = "URL of the ECR repository containing the Lambda image"
  type        = string
}

variable "rds_instance_id" {
  description = "The ID of the RDS instance"
  type        = string
}

variable "rds_secret_arn" {
  description = "The ARN of the RDS secret"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "The ID of the RDS security group"
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

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

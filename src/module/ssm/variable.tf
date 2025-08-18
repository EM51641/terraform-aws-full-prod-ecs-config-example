variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "rds_security_group_id" {
  description = "VPC security group ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

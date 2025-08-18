variable "project_name" {
  type = string
}
variable "env_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "rds_secret_arn" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "image" {
  type = string
}

variable "task_cpu" {
  type = string
}

variable "task_memory" {
  type = string
}

variable "region" {
  type = string
}

variable "rds_host" {
  type = string
}

variable "app_secret_arn" {
  type = string
}

variable "max_vcpus" {
  type = number
}

variable "rds_security_group_id" {
  description = "The security group ID of the RDS instance"
  type        = string
}

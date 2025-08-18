variable "public_subnets_ids" {
  description = "Public subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "s3_bucket_lb_logs_id" {
  description = "The ID of the ALB S3 bucket"
  type        = string
}

variable "s3_bucket_lb_logs_arn" {
  description = "The ARN of the ALB S3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
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

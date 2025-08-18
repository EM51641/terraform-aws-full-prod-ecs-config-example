variable "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}

variable "alb_domain_name" {
  description = "Domain name of the ALB"
  type        = string
}

variable "subdomains" {
  description = "List of subdomains for the CloudFront distribution"
  type        = list(string)
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "price_class" {
  description = "Price class"
  type        = string
}

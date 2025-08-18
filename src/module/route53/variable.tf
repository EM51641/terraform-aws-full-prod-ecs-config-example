variable "cloudfront_distribution_domain_name" {
  description = "cdn domain name of the CloudFront distribution"
  type        = string
}

variable "cloudfront_distribution_hosted_zone_id" {
  description = "cdn hosted zone ID of the CloudFront distribution"
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
# Static content bucket outputs
output "static_content_bucket_id" {
  description = "The ID of the static content bucket"
  value       = aws_s3_bucket.static_content_bucket.id
}

output "static_content_bucket_arn" {
  description = "The ARN of the static content bucket"
  value       = aws_s3_bucket.static_content_bucket.arn
}

output "static_content_bucket_domain_name" {
  description = "The domain name of the static content bucket"
  value       = aws_s3_bucket.static_content_bucket.bucket_regional_domain_name
}

output "static_content_bucket_policy_id" {
  description = "The ID of the bucket policy"
  value       = aws_s3_bucket_policy.static_content_policy.id
}

output "lb_logs_bucket_arn" {
  description = "The ARN of the ALB logs bucket"
  value       = aws_s3_bucket.lb_logs.arn
}

output "lb_logs_bucket_id" {
  description = "The ID of the ALB logs bucket"
  value       = aws_s3_bucket.lb_logs.id
}

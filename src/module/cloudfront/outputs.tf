output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_content_distribution.arn
}

output "cdn_distribution_domain_name" {
  description = "cdn domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_content_distribution.domain_name
}

output "cdn_distribution_hosted_zone_id" {
  description = "cdn hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_content_distribution.hosted_zone_id
}
output "zone_name" {
  description = "The name of the main Route53 zone"
  value       = data.aws_route53_zone.main.name
}

output "name_servers" {
  description = "The name servers for the main Route53 zone"
  value       = data.aws_route53_zone.main.name_servers
}

# CDN record outputs
output "cdn_record_name" {
  description = "The name of the CDN Route53 record"
  value       = aws_route53_record.cdn.name
}

output "cdn_record_fqdn" {
  description = "The FQDN of the CDN Route53 record"
  value       = aws_route53_record.cdn.fqdn
}

#ACM cdn certificate
output "acm_certificate_arn" {
  description = "The certificate arn for the cdn"
  value       = aws_acm_certificate.certificates.arn
}
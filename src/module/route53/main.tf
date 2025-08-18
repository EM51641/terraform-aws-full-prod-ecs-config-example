# Route53 zone
data "aws_route53_zone" "main" {
  name = "livedisplaced.com"
}

resource "aws_acm_certificate" "certificates" {
  domain_name = "www.${data.aws_route53_zone.main.name}"
  subject_alternative_names = [
    "cdn.${data.aws_route53_zone.main.name}",
    "*.${data.aws_route53_zone.main.name}"
  ]
  validation_method = "DNS"

  tags = {
    Name        = "${var.project_name}-${var.env_name}-route53-certificate"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Route53 record for ACM validation for cdn subnet
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificates.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# CDN validation
resource "aws_acm_certificate_validation" "cdn" {
  certificate_arn         = aws_acm_certificate.certificates.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}


# Route53 record for CloudFront (CDN subdomain)
resource "aws_route53_record" "cdn" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "cdn.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = var.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}


# Route53 record for CloudFront (WWW subdomain)
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = var.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
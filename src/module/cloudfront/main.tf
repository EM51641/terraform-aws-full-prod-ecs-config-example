# CloudFront for static content
resource "aws_cloudfront_distribution" "static_content_distribution" {
  price_class = var.price_class

  # S3 Origin
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_id                = "S3-${var.env_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_path              = ""
  }

  # ALB Origin
  origin {
    domain_name = var.alb_domain_name # Add this variable
    origin_id   = "ALB-${var.env_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.env_name}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = []
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"] # All HTTP methods allowed
    cached_methods         = ["GET", "HEAD"]                                              # Only GET and HEAD responses can be cached
    target_origin_id       = "ALB-${var.env_name}"                                        # Send to ALB
    viewer_protocol_policy = "redirect-to-https"                                          # Force HTTPS

    forwarded_values {
      query_string = true  # Forward all query parameters
      headers      = ["*"] # Forward all headers
      cookies {
        forward = "all" # Forward all cookies
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  # Add aliases for your domain
  aliases = var.subdomains

  tags = {
    Name        = "${var.project_name}-${var.env_name}-cloudfront"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# Create Origin Access Control
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "static-content-${var.env_name}-oac"
  description                       = "Origin Access Control for Static Content"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

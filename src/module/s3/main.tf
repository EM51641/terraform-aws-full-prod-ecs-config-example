# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.project_name}-${var.env_name}-alb-logs"
}


# Keep this to ensure no public access
resource "aws_s3_bucket_public_access_block" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Delete old logs after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

# S3 for static content
resource "aws_s3_bucket" "static_content_bucket" {
  bucket = "static-content-bucket-${var.env_name}"

  tags = {
    Name        = "static-content-bucket-${var.env_name}"
    Environment = var.env_name
    Project     = "${var.project_name}"
  }
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "static_content_policy" {
  bucket = aws_s3_bucket.static_content_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "${aws_s3_bucket.static_content_bucket.arn}",
          "${aws_s3_bucket.static_content_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# Providers
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "livedisplaced-terraform-state"
    key            = "image_backend/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

resource "aws_ecr_repository" "main" {
  name = "livedisplaced-global-ecr"

  tags = {
    Name        = "livedisplaced-global-ecr"
    Environment = "Global"
    Project     = "livedisplaced"
  }
}

data "aws_ecr_lifecycle_policy_document" "main" {
  rule {
    priority    = 1
    description = "Remove all images after 1 day"

    selection {
      tag_status   = "any" # Matches ALL images regardless of tag
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }

    action {
      type = "expire"
    }
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = data.aws_ecr_lifecycle_policy_document.main.json
}

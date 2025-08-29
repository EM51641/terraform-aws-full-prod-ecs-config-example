variable "region" {
  description = "Region"
  default     = "us-east-1"
}

variable "cidr_block" {
  description = "CIDR block"
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name"
  default     = "livedisplaced"
}

variable "env_name" {
  description = "Environment name"
  default     = "prod"
}

variable "github_org" {
  description = "GitHub organization"
  default     = "EM51641"
}

variable "github_repo" {
  description = "GitHub repository"
  default     = "livedisplaced"
}

variable "github_branch" {
  description = "GitHub branch"
  default     = "main"
}

variable "account_id" {
  description = "AWS account ID"
  default     = "XXXXXX"
}

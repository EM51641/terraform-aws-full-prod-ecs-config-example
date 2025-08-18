# Providers
provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = "livedisplaced-terraform-state"
    key            = "environments/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

data "aws_ecr_repository" "main" {
  name = "livedisplaced-global-ecr"
}

# Networking
module "vpc" {
  source       = "./vpc"
  env_name     = var.env_name
  project_name = var.project_name
  ecs_security_group_id    = module.ecs.security_group_id
  lambda_security_group_id = module.lambda.lambda_security_group_id
}

# Security
module "secret" {
source       = "../../module/secret"
env_name     = var.env_name
project_name = var.project_name
}

# Database
module "rds" {
source                   = "../../module/rds"
vpc_id                   = module.vpc.vpc_id
app_security_group_id    = module.ecs.security_group_id
lambda_security_group_id = module.lambda.lambda_security_group_id
batch_security_group_id  = module.batch.batch_security_group_id
subnet_ids               = [module.vpc.private_subnet_id, module.vpc.private_subnet_2_id]
instance_class           = "db.t4g.micro"
ssm_security_group_id    = module.ssm.ssm_security_group_id
env_name                 = var.env_name
project_name             = var.project_name
}

# Lambda
module "lambda" {
source                = "../../module/lambda"
vpc_id                = module.vpc.vpc_id
vpc_cidr_block        = module.vpc.vpc_cidr_block
subnet_ids            = [module.vpc.private_subnet_id]
rds_security_group_id = module.rds.db_security_group_id
ecr_repository_arn    = data.aws_ecr_repository.main.arn
rds_instance_id       = module.rds.rds_instance_id
rds_secret_arn        = module.rds.rds_secret_arn
env_name              = var.env_name
project_name          = var.project_name
}

# Application
module "ecs" {
source                = "../../module/ecs"
vpc_id                = module.vpc.vpc_id
vpc_cidr_block        = module.vpc.vpc_cidr_block
private_subnet_ids    = [module.vpc.private_subnet_id]
s3_static_bucket_arn  = module.s3.static_content_bucket_arn
secrets_manager_arn   = module.secret.app_secret_arn
ecr_repository_arn    = data.aws_ecr_repository.main.arn
lb_target_group_arn   = module.lb.lb_target_group_arn
lb_security_group_id  = module.lb.lb_security_group_id
rds_host              = module.rds.rds_host
rds_secret_arn        = module.rds.rds_secret_arn
rds_security_group_id = module.rds.db_security_group_id
app_secret_arn        = module.secret.app_secret_arn
ecr_repository_url    = data.aws_ecr_repository.main.repository_url
env_name              = var.env_name
project_name          = var.project_name
region                = var.region
task_cpu              = 256
task_memory           = 512
}

# Load Balancer
module "lb" {
source                = "../../module/lb"
vpc_id                = module.vpc.vpc_id
public_subnets_ids    = [module.vpc.public_subnet_id, module.vpc.public_subnet_2_id]
s3_bucket_lb_logs_arn = module.s3.lb_logs_bucket_arn
s3_bucket_lb_logs_id  = module.s3.lb_logs_bucket_id
acm_certificate_arn   = module.route53.acm_certificate_arn
env_name              = var.env_name
project_name          = var.project_name
}

# Storage
module "s3" {
  source = "../../module/s3"
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  env_name     = var.env_name
  project_name = var.project_name
}

# CDN & DNS
module "cloudfront" {
  source                = "../../module/cloudfront"
  s3_bucket_domain_name = module.s3.static_content_bucket_domain_name
  acm_certificate_arn   = module.route53.acm_certificate_arn
  domain_name           = module.route53.zone_name
  subdomains            = ["cdn.${module.route53.zone_name}", "www.${module.route53.zone_name}"]
  env_name              = var.env_name
  project_name          = var.project_name
  alb_domain_name       = module.lb.alb_domain_name
  price_class           = "PriceClass_100"
}

# Route53
module "route53" {
source                                 = "../../module/route53"
cloudfront_distribution_domain_name    = module.cloudfront.cdn_distribution_domain_name
cloudfront_distribution_hosted_zone_id = module.cloudfront.cdn_distribution_hosted_zone_id
env_name                               = var.env_name
project_name                           = var.project_name
}

# Budget
module "budget" {
source       = "../../module/budget"
project_name = var.project_name
env_name     = var.env_name
limit_amount = 15
}

# CI
module "ci_iam" {
source                            = "../../module/ci"
project_name                      = var.project_name
env_name                          = var.env_name
region                            = var.region
account_id                        = var.account_id
github_org                        = var.github_org
github_repo                       = var.github_repo
github_branch                     = var.github_branch
ecs_task_role_arn                 = module.ecs.task_role_arn
ecs_execution_role_arn            = module.ecs.execution_role_arn
ecs_family                        = module.ecs.ecs_family
service_arn                       = module.ecs.service_arn
ecr_repository_arn                = data.aws_ecr_repository.main.arn
ecs_task_cpu                      = module.ecs.task_cpu
ecs_task_memory                   = module.ecs.task_memory
s3_bucket_arn                     = module.s3.static_content_bucket_arn
lambda_function_arn               = module.lambda.lambda_function_arn
batch_ecs_task_execution_role_arn = module.batch.ecs_task_execution_role_arn
batch_ecs_task_role_arn           = module.batch.ecs_task_execution_role_arn
}

# SSM
module "ssm" {
source                = "../../module/ssm"
subnet_id             = module.vpc.public_subnet_id
vpc_id                = module.vpc.vpc_id
rds_security_group_id = module.rds.db_security_group_id
project_name          = var.project_name
env_name              = var.env_name
}

# Batch
module "batch" {
source                = "../../module/batch"
project_name          = var.project_name
env_name              = var.env_name
vpc_id                = module.vpc.vpc_id
subnets               = [module.vpc.private_subnet_id, module.vpc.private_subnet_2_id]
rds_secret_arn        = module.rds.rds_secret_arn
ecr_repository_arn    = data.aws_ecr_repository.main.arn
image                 = "010526276787.dkr.ecr.us-east-1.amazonaws.com/livedisplaced-global-ecr"
task_cpu              = "0.25"
task_memory           = "512"
region                = var.region
rds_host              = module.rds.rds_host
app_secret_arn        = module.secret.app_secret_arn
max_vcpus             = 1
rds_security_group_id = module.rds.db_security_group_id
}

# Production environment stack for AWS ECS Fargate.
# This file wires reusable infrastructure modules together.

module "networking" {
  source = "../../modules/networking"
  name   = var.project_name
  tags   = var.tags
}

module "security" {
  source = "../../modules/security"
  name   = var.project_name
  tags   = var.tags
}

module "ecr" {
  source = "../../modules/ecr"
  name   = var.project_name
  tags   = var.tags
}

module "ecs" {
  source = "../../modules/ecs"
  name   = var.project_name
  tags   = var.tags
}

module "alb" {
  source = "../../modules/alb"
  name   = var.project_name
  tags   = var.tags
}

module "rds" {
  source = "../../modules/rds"
  name   = var.project_name
  tags   = var.tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"
  name   = var.project_name
  tags   = var.tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  name   = var.project_name
  tags   = var.tags
}

module "iam" {
  source = "../../modules/iam"
  name   = var.project_name
  tags   = var.tags
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"
  name   = var.project_name
  tags   = var.tags
}

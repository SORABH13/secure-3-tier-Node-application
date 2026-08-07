module "networking" {
  source = "../../modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  tags                     = var.tags
}

module "security" {
  source = "../../modules/security"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  alb_ingress_cidrs      = var.alb_ingress_cidrs
  alb_ingress_ipv6_cidrs = var.alb_ingress_ipv6_cidrs
  tags                   = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
  force_delete = var.ecr_force_delete
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name         = var.project_name
  environment          = var.environment
  db_username          = var.db_username
  db_password          = var.db_password
  db_name              = var.db_name
  existing_secret_name = var.existing_db_secret_name
  tags                 = var.tags
}

module "iam" {
  source = "../../modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  ecr_repository_arns = [module.ecr.web_repository_arn, module.ecr.api_repository_arn]
  secret_arns         = [module.secrets_manager.db_secret_arn]
  tags                = var.tags
  # OIDC role creation disabled for this deployment
}

module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  db_username             = var.db_username
  db_password             = var.db_password
  db_name                 = var.db_name
  db_instance_class       = var.db_instance_class
  allocated_storage       = var.allocated_storage
  engine_version          = var.engine_version
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  db_subnet_ids           = module.networking.private_db_subnet_ids
  vpc_security_group_ids  = [module.security.postgres_security_group_id]
  tags                    = var.tags
}

module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  certificate_arn   = var.certificate_arn
  tags              = var.tags
}

module "ecs" {
  source = "../../modules/ecs"

  project_name                    = var.project_name
  environment                     = var.environment
  vpc_id                          = module.networking.vpc_id
  subnet_ids                      = module.networking.private_app_subnet_ids
  web_security_group_id           = module.security.web_security_group_id
  api_security_group_id           = module.security.api_security_group_id
  task_execution_role_arn         = module.iam.task_execution_role_arn
  task_role_arn                   = module.iam.task_role_arn
  web_image                       = var.web_image != "" ? var.web_image : format("%s:latest", module.ecr.web_repository_uri)
  api_image                       = var.api_image != "" ? var.api_image : format("%s:latest", module.ecr.api_repository_uri)
  db_host                         = module.rds.db_endpoint
  db_name                         = var.db_name
  db_username                     = var.db_username
  db_secret_arn                   = module.secrets_manager.db_secret_arn
  target_group_arn                = module.alb.target_group_arn
  api_service_discovery_namespace = format("%s-%s.local", var.project_name, var.environment)
  tags                            = var.tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name       = var.project_name
  environment        = var.environment
  origin_domain_name = module.alb.alb_dns_name
  certificate_arn    = var.certificate_arn
  aliases            = var.cloudfront_aliases
  tags               = var.tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name           = var.project_name
  environment            = var.environment
  cluster_name           = module.ecs.cluster_name
  web_service_name       = module.ecs.web_service_name
  api_service_name       = module.ecs.api_service_name
  load_balancer_arn      = module.alb.alb_arn
  target_group_arn       = module.alb.target_group_arn
  db_instance_identifier = module.rds.db_instance_identifier
  tags                   = var.tags
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.domain_name
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "web_service_name" {
  description = "Web ECS service name."
  value       = module.ecs.web_service_name
}

output "api_service_name" {
  description = "API ECS service name."
  value       = module.ecs.api_service_name
}

output "web_repository_uri" {
  description = "ECR repository URI for the Web service."
  value       = module.ecr.web_repository_uri
}

output "api_repository_uri" {
  description = "ECR repository URI for the API service."
  value       = module.ecr.api_repository_uri
}

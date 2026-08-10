output "vpc_id" {
  description = "VPC ID created by the networking module."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs from networking module."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs from networking module."
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private DB subnet IDs from networking module."
  value       = module.networking.private_db_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (one per AZ) from networking module."
  value       = module.networking.nat_gateway_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID from networking module."
  value       = module.networking.internet_gateway_id
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

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN that CloudWatch alarms publish to."
  value       = module.cloudwatch.sns_topic_arn
}

output "cloudtrail_bucket" {
  description = "S3 bucket storing CloudTrail audit logs."
  value       = module.cloudtrail.bucket_name
}

output "waf_web_acl_arn" {
  description = "ARN of the WAFv2 web ACL protecting CloudFront."
  value       = module.waf.web_acl_arn
}

output "backup_vault_name" {
  description = "Name of the AWS Backup vault holding RDS recovery points."
  value       = module.backup.vault_name
}

output "github_app_deploy_role_arn" {
  description = "IAM role ARN for GitHub Actions app.yml to assume via OIDC (set as AWS_APP_DEPLOY_ROLE_ARN repo variable)."
  value       = module.iam.github_app_deploy_role_arn
}

output "github_terraform_role_arn" {
  description = "IAM role ARN for GitHub Actions infra.yml to assume via OIDC (set as AWS_TERRAFORM_ROLE_ARN repo variable)."
  value       = module.iam.github_terraform_role_arn
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name for the Web service, used by app.yml to trigger blue/green deployments."
  value       = module.codedeploy.app_name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name for the Web service."
  value       = module.codedeploy.deployment_group_name
}

output "web_green_target_group_arn" {
  description = "ARN of the green target group for the Web service."
  value       = module.alb.green_target_group_arn
}

variable "project_name" {
  description = "Project name used across the production environment."
  type        = string
  default     = "toptal"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for production resources."
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Availability zones for networking subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR ranges permitted to reach the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_ingress_ipv6_cidrs" {
  description = "IPv6 CIDR ranges permitted to reach the ALB."
  type        = list(string)
  default     = ["::/0"]
}

variable "db_username" {
  description = "Master database username."
  type        = string
  default     = "toptaladmin"
}

variable "existing_db_secret_name" {
  description = "Existing active Secrets Manager secret name to reuse for database credentials."
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "toptal"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for RDS in GB."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.18"
}

variable "backup_retention_period" {
  description = "RDS backup retention days."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection for RDS."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final RDS snapshot during teardown."
  type        = bool
  default     = false
}

variable "ecr_force_delete" {
  description = "Delete ECR repositories even when they contain images. Intended only for teardown."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for the ALB and CloudFront origin."
  type        = string
  default     = ""
}

variable "alb_health_check_path" {
  description = "A lightweight Web endpoint or static asset that returns HTTP 200 without calling the API."
  type        = string
  default     = "/stylesheets/style.css"
}

variable "cloudfront_aliases" {
  description = "Optional CloudFront aliases."
  type        = list(string)
  default     = []
}

variable "web_image" {
  description = "ECR image URI for the Web service."
  type        = string
  default     = ""
}

variable "api_image" {
  description = "ECR image URI for the API service."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project     = "toptal"
    Environment = "prod"
  }
}

variable "web_desired_count" {
  description = "Desired task count for the Web ECS service."
  type        = number
  default     = 2
}

variable "api_desired_count" {
  description = "Desired task count for the API ECS service."
  type        = number
  default     = 2
}

variable "alert_email" {
  description = "Email address subscribed to the CloudWatch alarms SNS topic. Leave empty to skip (wire a PagerDuty/Opsgenie HTTPS endpoint for real production paging)."
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Number of days AWS Backup retains each RDS recovery point."
  type        = number
  default     = 35
}

variable "backup_schedule" {
  description = "Cron expression (AWS Backup syntax) for the daily backup job."
  type        = string
  default     = "cron(0 7 * * ? *)"
}

variable "enable_github_oidc" {
  description = "Create the GitHub Actions OIDC provider and deploy/terraform IAM roles."
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the OIDC roles, in \"org/repo\" form. Leave empty to skip OIDC role creation entirely."
  type        = string
  default     = "SORABH13/secure-3-tier-Node-application"
}

variable "github_allowed_refs" {
  description = "Branches allowed to assume the OIDC roles. Must include every branch either workflow's trigger runs on -- infra.yml currently also triggers on feature/project-analysis; drop it here once that branch is merged/deleted."
  type        = list(string)
  default     = ["master", "feature/project-analysis"]
}

variable "waf_rate_limit" {
  description = "Max requests from a single IP per 5-minute window before the CloudFront WAF rate-based rule blocks it."
  type        = number
  default     = 2000
}

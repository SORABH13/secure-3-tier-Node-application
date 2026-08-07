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

variable "db_password" {
  description = "Master database password."
  type        = string
  sensitive   = true
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

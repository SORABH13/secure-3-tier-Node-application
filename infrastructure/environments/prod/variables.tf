variable "aws_region" {
  description = "AWS region for the production environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "secure-3-tier-node-application"
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "secure-3-tier-node-application"
  }
}

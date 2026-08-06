variable "project_name" {
  description = "Project name used for ECS naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for ECS naming and tagging."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for ECS service deployment."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks."
  type        = list(string)
}

variable "web_security_group_id" {
  description = "Security group ID assigned to the Web ECS service."
  type        = string
}

variable "api_security_group_id" {
  description = "Security group ID assigned to the API ECS service."
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role."
  type        = string
}

variable "web_image" {
  description = "ECR image URI for the Web ECS service."
  type        = string
}

variable "api_image" {
  description = "ECR image URI for the API ECS service."
  type        = string
}

variable "web_service_port" {
  description = "Port used by the Web service container."
  type        = number
  default     = 3000
}

variable "api_service_port" {
  description = "Port used by the API service container."
  type        = number
  default     = 3001
}

variable "target_group_arn" {
  description = "ARN of the ALB target group for the Web ECS service."
  type        = string
}

variable "web_desired_count" {
  description = "Desired count for the Web ECS service."
  type        = number
  default     = 2
}

variable "api_desired_count" {
  description = "Desired count for the API ECS service."
  type        = number
  default     = 2
}

variable "web_cpu" {
  description = "CPU units for the Web ECS task."
  type        = number
  default     = 512
}

variable "web_memory" {
  description = "Memory in MB for the Web ECS task."
  type        = number
  default     = 1024
}

variable "api_cpu" {
  description = "CPU units for the API ECS task."
  type        = number
  default     = 512
}

variable "api_memory" {
  description = "Memory in MB for the API ECS task."
  type        = number
  default     = 1024
}

variable "db_host" {
  description = "Database hostname for the API ECS service."
  type        = string
}

variable "db_name" {
  description = "Database name for the API ECS service."
  type        = string
}

variable "db_username" {
  description = "Database username for the API ECS service."
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database credentials secret."
  type        = string
}

variable "api_service_discovery_namespace" {
  description = "Optional private DNS namespace name for API service discovery."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags applied to ECS resources."
  type        = map(string)
  default     = {}
}

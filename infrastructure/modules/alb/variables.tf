variable "project_name" {
  description = "Project name used for ALB naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for ALB naming and tagging."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the ALB."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs where the ALB will be deployed."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the ALB."
  type        = string
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags applied to ALB resources."
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Health check path for the ALB target group."
  type        = string
  default     = "/"
}

variable "target_group_port" {
  description = "Target group port for the Web ECS service."
  type        = number
  default     = 3000
}

variable "project_name" {
  description = "Project name used for security group naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment" {
  description = "Environment used for security group naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment cannot be empty."
  }
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id cannot be empty."
  }
}

variable "alb_http_port" {
  description = "HTTP listener port for the ALB."
  type        = number
  default     = 80
}

variable "alb_https_port" {
  description = "HTTPS listener port for the ALB."
  type        = number
  default     = 443
}

variable "web_service_port" {
  description = "Port used by the Web ECS service."
  type        = number
  default     = 3000
}

variable "api_service_port" {
  description = "Port used by the API ECS service."
  type        = number
  default     = 3001
}

variable "db_port" {
  description = "Port used by PostgreSQL."
  type        = number
  default     = 5432
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR ranges permitted to reach the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0
    error_message = "alb_ingress_cidrs must contain at least one CIDR block."
  }
}

variable "alb_ingress_ipv6_cidrs" {
  description = "IPv6 CIDR ranges permitted to reach the ALB."
  type        = list(string)
  default     = ["::/0"]

  validation {
    condition     = length(var.alb_ingress_ipv6_cidrs) > 0
    error_message = "alb_ingress_ipv6_cidrs must contain at least one IPv6 CIDR block."
  }
}

variable "tags" {
  description = "Additional tags to apply to all security resources."
  type        = map(string)
  default     = {}
}

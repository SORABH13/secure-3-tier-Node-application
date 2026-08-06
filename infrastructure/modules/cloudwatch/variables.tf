variable "project_name" {
  description = "Project name used for CloudWatch naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for CloudWatch naming and tagging."
  type        = string
}

variable "dashboard_name" {
  description = "CloudWatch dashboard name."
  type        = string
  default     = "node3tier-prod-dashboard"
}

variable "log_group_names" {
  description = "List of CloudWatch log group names to create."
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "ECS cluster name for dashboard metrics."
  type        = string
}

variable "web_service_name" {
  description = "ECS Web service name for dashboard metrics."
  type        = string
}

variable "api_service_name" {
  description = "ECS API service name for dashboard metrics."
  type        = string
}

variable "load_balancer_arn" {
  description = "ARN of the Application Load Balancer for ALB metrics."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group for metrics."
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS instance identifier for dashboard metrics."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to CloudWatch resources."
  type        = map(string)
  default     = {}
}

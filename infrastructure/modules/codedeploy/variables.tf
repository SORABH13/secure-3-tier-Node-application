variable "project_name" {
  description = "Project name used for CodeDeploy resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for CodeDeploy resource naming and tagging."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name running the Web service."
  type        = string
}

variable "web_service_name" {
  description = "Name of the Web ECS service (deployment_controller = CODE_DEPLOY)."
  type        = string
}

variable "production_listener_arn" {
  description = "ARN of the ALB listener CodeDeploy shifts production traffic on."
  type        = string
}

variable "blue_target_group_name" {
  description = "Name of the blue (currently live) target group."
  type        = string
}

variable "green_target_group_name" {
  description = "Name of the green target group CodeDeploy deploys the new revision to."
  type        = string
}

variable "deployment_config_name" {
  description = "Built-in ECS CodeDeploy traffic-shifting config."
  type        = string
  default     = "CodeDeployDefault.ECSCanary10Percent5Minutes"
}

variable "termination_wait_time_minutes" {
  description = "Minutes to keep the old (blue) task set running after a successful deployment before terminating it, in case a fast rollback is needed."
  type        = number
  default     = 5
}

variable "alarm_names" {
  description = "CloudWatch alarm names that trigger automatic deployment rollback if they go into ALARM during a deployment."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to CodeDeploy resources."
  type        = map(string)
  default     = {}
}

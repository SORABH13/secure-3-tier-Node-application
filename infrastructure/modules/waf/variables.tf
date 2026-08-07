variable "project_name" {
  description = "Project name used for WAF resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for WAF resource naming and tagging."
  type        = string
}

variable "rate_limit" {
  description = "Max requests from a single IP per 5-minute window before the rate-based rule blocks it."
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Additional tags applied to WAF resources."
  type        = map(string)
  default     = {}
}

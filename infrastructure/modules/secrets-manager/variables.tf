variable "project_name" {
  description = "Project name used for secret naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for secret naming and tagging."
  type        = string
}

variable "db_username" {
  description = "Database username stored in Secrets Manager."
  type        = string
}

variable "db_password" {
  description = "Database password stored in Secrets Manager."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name stored in Secrets Manager."
  type        = string
  default     = "node3tier"
}

variable "tags" {
  description = "Additional tags applied to Secrets Manager resources."
  type        = map(string)
  default     = {}
}

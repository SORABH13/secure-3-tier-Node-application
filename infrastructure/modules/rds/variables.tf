variable "project_name" {
  description = "Project name used for RDS resource naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment" {
  description = "Environment used for RDS resource naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment cannot be empty."
  }
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance."
  type        = string

  validation {
    condition     = length(trimspace(var.db_username)) > 0
    error_message = "db_username cannot be empty."
  }
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Initial database name for PostgreSQL."
  type        = string
  default     = "node3tier"
}

variable "db_instance_class" {
  description = "RDS instance class for PostgreSQL."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB for PostgreSQL."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.4"
}

variable "backup_retention_period" {
  description = "Automated backup retention period in days."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection for the RDS instance."
  type        = bool
  default     = true
}

variable "db_subnet_ids" {
  description = "List of private DB subnet IDs for the RDS subnet group."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the RDS instance."
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to RDS resources."
  type        = map(string)
  default     = {}
}

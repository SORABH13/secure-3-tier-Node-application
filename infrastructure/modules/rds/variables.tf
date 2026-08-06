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

  validation {
    condition = (
      can(regex("^[!-~]{8,41}$", var.db_password)) &&
      !can(regex("[/@\\x22]", var.db_password))
    )
    error_message = "db_password must be 8-41 printable ASCII characters and must not contain '/', '@', double quotes, or spaces."
  }
}

variable "db_name" {
  description = "Initial database name for PostgreSQL."
  type        = string
  default     = "toptal"
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

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GB for this RDS instance."
  }
}

variable "engine_version" {
  description = "Explicit PostgreSQL engine version, including its major version."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", var.engine_version))
    error_message = "engine_version must be an explicit version such as 15.18."
  }
}

variable "backup_retention_period" {
  description = "Automated backup retention period in days."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35 days."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for the RDS instance."
  type        = bool
  default     = true
}

variable "db_subnet_ids" {
  description = "List of private DB subnet IDs for the RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_ids) >= 2
    error_message = "db_subnet_ids must contain at least two subnets in different Availability Zones."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the RDS instance."
  type        = list(string)

  validation {
    condition     = length(var.vpc_security_group_ids) > 0
    error_message = "vpc_security_group_ids must contain at least one security group."
  }
}

variable "tags" {
  description = "Additional tags to apply to RDS resources."
  type        = map(string)
  default     = {}
}

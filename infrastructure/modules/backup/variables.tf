variable "project_name" {
  description = "Project name used for AWS Backup resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for AWS Backup resource naming and tagging."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS CMK ARN used to encrypt the backup vault."
  type        = string
}

variable "rds_instance_arn" {
  description = "ARN of the RDS instance to include in the daily backup selection."
  type        = string
}

variable "schedule" {
  description = "Cron expression (AWS Backup syntax) for the daily backup job."
  type        = string
  default     = "cron(0 7 * * ? *)" # 07:00 UTC daily
}

variable "retention_days" {
  description = "Number of days AWS Backup retains each recovery point."
  type        = number
  default     = 35
}

variable "cold_storage_after_days" {
  description = "Days before a recovery point transitions to cold storage. 0 disables cold storage transition."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Additional tags applied to AWS Backup resources."
  type        = map(string)
  default     = {}
}

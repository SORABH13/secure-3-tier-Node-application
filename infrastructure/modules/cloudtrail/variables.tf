variable "project_name" {
  description = "Project name used for CloudTrail resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for CloudTrail resource naming and tagging."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS CMK ARN used to encrypt CloudTrail log files."
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain CloudTrail log files in S3 before expiry."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Additional tags applied to CloudTrail resources."
  type        = map(string)
  default     = {}
}

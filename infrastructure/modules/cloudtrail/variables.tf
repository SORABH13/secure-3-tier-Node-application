variable "project_name" {
  description = "Project name used for CloudTrail resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for CloudTrail resource naming and tagging."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS CMK ARN used to encrypt CloudTrail log files (S3). Must be a key whose policy grants cloudtrail.amazonaws.com -- see the kms module's dedicated cloudtrail_key_arn output."
  type        = string
}

variable "log_group_kms_key_arn" {
  description = "KMS CMK ARN used to encrypt the CloudTrail CloudWatch Logs group. Must be a key whose policy grants logs.amazonaws.com -- see the kms module's data_key_arn output. Leave empty to use CloudWatch's default encryption."
  type        = string
  default     = ""
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

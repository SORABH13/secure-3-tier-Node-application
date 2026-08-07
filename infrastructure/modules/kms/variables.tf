variable "project_name" {
  description = "Project name used for KMS resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for KMS resource naming and tagging."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to KMS resources."
  type        = map(string)
  default     = {}
}

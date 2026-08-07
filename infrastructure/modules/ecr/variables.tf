variable "project_name" {
  description = "Project name used for ECR repository naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment" {
  description = "Environment used for ECR repository naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment cannot be empty."
  }
}

variable "tags" {
  description = "Additional tags applied to ECR repositories."
  type        = map(string)
  default     = {}
}

variable "image_tag_mutability" {
  description = "Image tag mutability for ECR repositories."
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Allow deletion of repositories that still contain images. Intended only for teardown."
  type        = bool
  default     = false
}

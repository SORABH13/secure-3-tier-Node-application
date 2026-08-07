variable "project_name" {
  description = "Project name used for IAM resource naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment" {
  description = "Environment used for IAM resource naming and tagging."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment cannot be empty."
  }
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs that task execution role should access."
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "List of Secrets Manager ARNs that ECS tasks require."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to IAM resources."
  type        = map(string)
  default     = {}
}

variable "enable_github_oidc" {
  description = "Create a GitHub Actions OIDC provider and deploy/terraform roles so CI can assume roles instead of using long-lived static AWS keys."
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the OIDC roles, in \"org/repo\" form."
  type        = string
  default     = ""
}

variable "github_allowed_refs" {
  description = "Git refs (branches) allowed to assume the OIDC roles, e.g. [\"master\"]. Each entry is expanded to repo:<github_repository>:ref:refs/heads/<branch>."
  type        = list(string)
  default     = ["master"]
}


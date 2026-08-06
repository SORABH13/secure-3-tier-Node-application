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

variable "github_oidc_provider_arn" {
  description = "OIDC provider ARN for GitHub Actions (e.g. arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com)."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository in the form owner/repo used to scope the OIDC trust (e.g. sourabhyogi/repo)."
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "Branch name to allow when scoping the OIDC trust (e.g. main or master). Use '*' for any branch."
  type        = string
  default     = "main"
}

variable "github_actions_role_name" {
  description = "Optional name for the IAM role created for GitHub Actions assume via OIDC."
  type        = string
  default     = ""
}

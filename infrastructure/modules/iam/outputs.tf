output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.task_execution.arn
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role."
  value       = aws_iam_role.task_execution.name
}

output "task_role_arn" {
  description = "ARN of the ECS task role."
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the ECS task role."
  value       = aws_iam_role.task.name
}

output "github_app_deploy_role_arn" {
  description = "ARN of the OIDC role GitHub Actions assumes to build/push images and deploy ECS services. Empty when github_oidc is disabled."
  value       = local.github_oidc_enabled ? aws_iam_role.github_app_deploy[0].arn : ""
}

output "github_terraform_role_arn" {
  description = "ARN of the OIDC role GitHub Actions assumes to run terraform plan/apply. Empty when github_oidc is disabled."
  value       = local.github_oidc_enabled ? aws_iam_role.github_terraform[0].arn : ""
}

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

output "github_actions_role_arn" {
  description = "ARN of the IAM role GitHub Actions can assume via OIDC (if created)."
  value       = length(aws_iam_role.github_actions) > 0 ? aws_iam_role.github_actions[0].arn : ""
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role."
  value       = length(aws_iam_role.github_actions) > 0 ? aws_iam_role.github_actions[0].name : ""
}

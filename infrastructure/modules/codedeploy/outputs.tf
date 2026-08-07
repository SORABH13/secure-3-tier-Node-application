output "app_name" {
  description = "CodeDeploy application name."
  value       = aws_codedeploy_app.web.name
}

output "deployment_group_name" {
  description = "CodeDeploy deployment group name for the Web service."
  value       = aws_codedeploy_deployment_group.web.deployment_group_name
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.this.arn
}

output "web_service_name" {
  description = "Web ECS service name."
  value       = aws_ecs_service.web.name
}

output "api_service_name" {
  description = "API ECS service name."
  value       = aws_ecs_service.api.name
}

output "web_task_definition_arn" {
  description = "ARN of the Web ECS task definition."
  value       = aws_ecs_task_definition.web.arn
}

output "api_task_definition_arn" {
  description = "ARN of the API ECS task definition."
  value       = aws_ecs_task_definition.api.arn
}

output "web_log_group_name" {
  description = "CloudWatch log group for the Web ECS task."
  value       = aws_cloudwatch_log_group.web.name
}

output "api_log_group_name" {
  description = "CloudWatch log group for the API ECS task."
  value       = aws_cloudwatch_log_group.api.name
}

output "api_service_discovery_namespace" {
  description = "Private DNS namespace used by API service discovery."
  value       = var.api_service_discovery_namespace
}

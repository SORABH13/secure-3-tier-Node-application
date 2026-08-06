output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "log_group_names" {
  description = "Created CloudWatch log group names."
  value       = [for log_group in aws_cloudwatch_log_group.this : log_group.name]
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic that CloudWatch alarms publish to."
  value       = aws_sns_topic.alerts.arn
}

output "deployment_rollback_alarm_names" {
  description = "Alarm names CodeDeploy watches to auto-rollback a Web deployment mid-flight."
  value = [
    aws_cloudwatch_metric_alarm.alb_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name,
  ]
}

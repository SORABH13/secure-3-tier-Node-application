output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the web target group."
  value       = aws_lb_target_group.web.arn
}

output "target_group_name" {
  description = "Name of the web target group."
  value       = aws_lb_target_group.web.name
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener if created."
  value       = try(aws_lb_listener.https[0].arn, "")
}

output "green_target_group_arn" {
  description = "ARN of the CodeDeploy green target group for the Web service."
  value       = aws_lb_target_group.web_green.arn
}

output "green_target_group_name" {
  description = "Name of the CodeDeploy green target group for the Web service."
  value       = aws_lb_target_group.web_green.name
}

output "production_listener_arn" {
  description = "ARN of the listener CodeDeploy shifts production traffic on (HTTPS if certificate_arn is set, otherwise HTTP)."
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
}

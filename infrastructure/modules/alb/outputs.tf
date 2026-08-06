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

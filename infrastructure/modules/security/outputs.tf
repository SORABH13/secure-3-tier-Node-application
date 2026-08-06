output "alb_security_group_id" {
  description = "Security group ID for the ALB."
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "Security group ID for the Web ECS service."
  value       = aws_security_group.web.id
}

output "api_security_group_id" {
  description = "Security group ID for the API ECS service."
  value       = aws_security_group.api.id
}

output "postgres_security_group_id" {
  description = "Security group ID for PostgreSQL RDS."
  value       = aws_security_group.postgres.id
}

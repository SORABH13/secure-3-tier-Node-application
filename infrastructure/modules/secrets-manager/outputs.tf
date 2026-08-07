output "db_secret_arn" {
  description = "ARN of the database credentials secret."
  value       = local.secret_arn
}

output "db_secret_name" {
  description = "Name of the database credentials secret."
  value       = local.secret_name
}

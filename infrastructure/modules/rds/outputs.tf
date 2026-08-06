output "db_instance_identifier" {
  description = "Identifier of the RDS instance."
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "Endpoint address of the PostgreSQL instance."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port used by the PostgreSQL instance."
  value       = aws_db_instance.this.port
}

output "db_subnet_group_name" {
  description = "RDS DB subnet group name."
  value       = aws_db_subnet_group.this.name
}

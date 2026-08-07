output "vault_name" {
  description = "Name of the AWS Backup vault."
  value       = aws_backup_vault.this.name
}

output "plan_id" {
  description = "ID of the AWS Backup plan."
  value       = aws_backup_plan.this.id
}

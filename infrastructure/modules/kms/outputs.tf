output "data_key_arn" {
  description = "ARN of the CMK used for RDS, Secrets Manager, and Backup encryption."
  value       = aws_kms_key.data.arn
}

output "data_key_id" {
  description = "Key ID of the data CMK."
  value       = aws_kms_key.data.key_id
}

output "cloudtrail_key_arn" {
  description = "ARN of the CMK used for CloudTrail log encryption."
  value       = aws_kms_key.cloudtrail.arn
}

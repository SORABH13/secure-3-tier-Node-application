output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "bucket_name" {
  description = "S3 bucket name storing CloudTrail audit logs."
  value       = aws_s3_bucket.trail.id
}

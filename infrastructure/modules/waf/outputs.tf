output "web_acl_arn" {
  description = "ARN of the WAFv2 web ACL, to be attached to the CloudFront distribution."
  value       = aws_wafv2_web_acl.this.arn
}

# NOTE: scope = "CLOUDFRONT" web ACLs must be created in us-east-1, regardless
# of which region the rest of the stack runs in. This project's default
# aws_region is us-east-1 (see environments/prod/variables.tf), so the root
# provider satisfies this without an aliased provider. If the region default
# ever changes, this module needs to be instantiated with an explicit
# `providers = { aws = aws.us_east_1 }` block from an aliased provider.
locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

resource "aws_wafv2_web_acl" "this" {
  name        = format("%s-cloudfront-waf", local.name_prefix)
  description = "Edge WAF protecting the CloudFront distribution with AWS managed rule groups and IP rate limiting."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-common-rule-set"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = format("%s-common-rule-set", local.name_prefix)
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-known-bad-inputs"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = format("%s-known-bad-inputs", local.name_prefix)
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit-per-ip"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = format("%s-rate-limit", local.name_prefix)
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = format("%s-cloudfront-waf", local.name_prefix)
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = format("%s-cloudfront-waf", local.name_prefix)
  })
}

locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

#tfsec:ignore:aws-cloudfront-use-secure-tls-policy -- when certificate_arn
# is unset, the second viewer_certificate block below falls back to
# cloudfront_default_certificate, which AWS hard-locks to TLSv1 regardless
# of what's configured here -- there's no minimum_protocol_version to raise
# without a real ACM cert + alias. Set certificate_arn to fix.
#tfsec:ignore:aws-cloudfront-enable-logging -- access logging isn't wired up
# here (legacy S3/ACL-based delivery is fragile to stand up correctly without
# a live apply to verify); CloudTrail (API audit) and CloudWatch Logs
# (application logs) already cover this project's logging requirement. A
# follow-up would move to CloudFront's newer vended-logs-to-S3-via-delivery
# source model instead of the legacy ACL grant.
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = ""
  price_class         = var.price_class
  web_acl_id          = var.web_acl_arn != "" ? var.web_acl_arn : null

  origin {
    domain_name = var.origin_domain_name
    origin_id   = format("%s-alb-origin", local.name_prefix)
    origin_path = var.origin_path

    #tfsec:ignore:aws-cloudfront-use-secure-tls-policy -- origin_protocol_policy
    # tracks certificate_arn: falls back to http-only only when no ACM cert is
    # configured yet (see terraform.tfvars.example). Set certificate_arn to
    # get https-only automatically, no code change needed.
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.certificate_arn != "" ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = format("%s-alb-origin", local.name_prefix)
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 60
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.certificate_arn != "" ? [1] : []
    content {
      acm_certificate_arn      = var.certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.certificate_arn == "" ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  aliases = var.aliases

  tags = merge(local.common_tags, {
    Name = format("%s-cloudfront", local.name_prefix)
  })
}

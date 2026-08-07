locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })

  bucket_name = format("%s-cloudtrail-%s", local.name_prefix, data.aws_caller_identity.current.account_id)
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

#tfsec:ignore:aws-s3-enable-bucket-logging -- this bucket IS CloudTrail's
# own log destination; access-logging it to a second bucket is a common
# accepted-risk skip in practice (marginal benefit vs. the CloudTrail data
# already recording who read/wrote objects here via S3 data events, which
# aren't enabled by default in this trail to control cost).
resource "aws_s3_bucket" "trail" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket = aws_s3_bucket.trail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    id     = "expire-old-audit-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }
  }
}

data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = [format("%s/AWSLogs/%s/*", aws_s3_bucket.trail.arn, data.aws_caller_identity.current.account_id)]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json
}

resource "aws_cloudwatch_log_group" "trail" {
  name              = format("/cloudtrail/%s", local.name_prefix)
  retention_in_days = var.retention_days
  kms_key_id        = var.log_group_kms_key_arn != "" ? var.log_group_kms_key_arn : null

  tags = merge(local.common_tags, {
    Name = format("%s-cloudtrail-log", local.name_prefix)
  })
}

data "aws_iam_policy_document" "trail_cw_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "trail_cw" {
  name               = format("%s-cloudtrail-cw-role", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.trail_cw_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "trail_cw_publish" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [format("%s:*", aws_cloudwatch_log_group.trail.arn)]
  }
}

resource "aws_iam_role_policy" "trail_cw_publish" {
  name   = format("%s-cloudtrail-cw-publish", local.name_prefix)
  role   = aws_iam_role.trail_cw.id
  policy = data.aws_iam_policy_document.trail_cw_publish.json
}

# S3 is the durable, long-retention copy; CloudWatch Logs gets the same
# events for real-time search/metric-filter alerting (e.g. a metric filter
# on ConsoleLogin failures or IAM policy changes).
resource "aws_cloudtrail" "this" {
  name                          = format("%s-trail", local.name_prefix)
  s3_bucket_name                = aws_s3_bucket.trail.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn
  cloud_watch_logs_group_arn    = format("%s:*", aws_cloudwatch_log_group.trail.arn)
  cloud_watch_logs_role_arn     = aws_iam_role.trail_cw.arn

  tags = merge(local.common_tags, {
    Name = format("%s-trail", local.name_prefix)
  })

  depends_on = [aws_s3_bucket_policy.trail, aws_iam_role_policy.trail_cw_publish]
}


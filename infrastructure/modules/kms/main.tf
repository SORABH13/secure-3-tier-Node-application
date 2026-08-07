locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

data "aws_caller_identity" "current" {}

# Single customer-managed key for RDS storage, Secrets Manager, and AWS Backup
# vault encryption. Rotation is enabled so the underlying key material is
# rotated yearly by AWS without any re-encryption of existing data.
resource "aws_kms_key" "data" {
  description             = format("%s data encryption key (RDS, Secrets Manager, Backup).", local.name_prefix)
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.data_key.json

  tags = merge(local.common_tags, {
    Name = format("%s-data-key", local.name_prefix)
  })
}

resource "aws_kms_alias" "data" {
  name          = format("alias/%s-data", local.name_prefix)
  target_key_id = aws_kms_key.data.key_id
}

data "aws_iam_policy_document" "data_key" {
  statement {
    sid    = "EnableRootAccountFullAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowServiceUseForDataEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com", "secretsmanager.amazonaws.com", "backup.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]
  }
}

# CloudTrail requires a dedicated key policy shape (encryption-context bound
# to the specific trail ARN), so it gets its own CMK rather than sharing the
# data key above.
resource "aws_kms_key" "cloudtrail" {
  description             = format("%s CloudTrail log encryption key.", local.name_prefix)
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudtrail_key.json

  tags = merge(local.common_tags, {
    Name = format("%s-cloudtrail-key", local.name_prefix)
  })
}

resource "aws_kms_alias" "cloudtrail" {
  name          = format("alias/%s-cloudtrail", local.name_prefix)
  target_key_id = aws_kms_key.cloudtrail.key_id
}

data "aws_iam_policy_document" "cloudtrail_key" {
  statement {
    sid    = "EnableRootAccountFullAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailToEncryptLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = [format("arn:aws:cloudtrail:*:%s:trail/*", data.aws_caller_identity.current.account_id)]
    }
  }

  statement {
    sid    = "AllowCloudTrailToDescribeKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }
}

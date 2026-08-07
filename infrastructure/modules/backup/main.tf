locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

resource "aws_backup_vault" "this" {
  name        = format("%s-backup-vault", local.name_prefix)
  kms_key_arn = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = format("%s-backup-vault", local.name_prefix)
  })
}

resource "aws_backup_plan" "this" {
  name = format("%s-backup-plan", local.name_prefix)

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.schedule
    start_window      = 60  # minutes to start before being marked missed
    completion_window = 480 # minutes to complete before being marked failed

    lifecycle {
      delete_after       = var.retention_days
      cold_storage_after = var.cold_storage_after_days > 0 ? var.cold_storage_after_days : null
    }
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = format("%s-backup-role", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "rds" {
  name         = format("%s-rds-selection", local.name_prefix)
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this.id
  resources    = [var.rds_instance_arn]
}

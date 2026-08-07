locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)
  secret_name = var.existing_secret_name != "" ? data.aws_secretsmanager_secret.existing[0].name : format("%s-db-credentials", local.name_prefix)
  secret_id   = var.existing_secret_name != "" ? data.aws_secretsmanager_secret.existing[0].id : aws_secretsmanager_secret.db_credentials[0].id
  secret_arn  = var.existing_secret_name != "" ? data.aws_secretsmanager_secret.existing[0].arn : aws_secretsmanager_secret.db_credentials[0].arn

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

data "aws_secretsmanager_secret" "existing" {
  count = var.existing_secret_name != "" ? 1 : 0

  name = var.existing_secret_name
}

resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.existing_secret_name == "" ? 1 : 0

  name = format("%s-db-credentials", local.name_prefix)

  tags = merge(local.common_tags, {
    Name = format("%s-db-credentials", local.name_prefix)
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = local.secret_id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    database = var.db_name
  })
}

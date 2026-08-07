locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })

  engine_major_version = split(".", var.engine_version)[0]
}

resource "aws_db_parameter_group" "this" {
  name        = format("%s-postgres%s-parameters", local.name_prefix, local.engine_major_version)
  family      = format("postgres%s", local.engine_major_version)
  description = "Parameter group for toptal PostgreSQL."

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = format("%s-postgres%s-parameters", local.name_prefix, local.engine_major_version)
  })
}

resource "aws_db_subnet_group" "this" {
  name       = format("%s-db-subnet-group", local.name_prefix)
  subnet_ids = var.db_subnet_ids

  tags = merge(local.common_tags, {
    Name = format("%s-db-subnet-group", local.name_prefix)
  })
}

resource "aws_db_instance" "this" {
  identifier                = format("%s-db", local.name_prefix)
  engine                    = "postgres"
  engine_version            = var.engine_version
  instance_class            = var.db_instance_class
  allocated_storage         = var.allocated_storage
  storage_encrypted         = true
  kms_key_id                = var.kms_key_id != "" ? var.kms_key_id : null
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = var.vpc_security_group_ids
  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : format("%s-final-snapshot", local.name_prefix)
  copy_tags_to_snapshot     = true
  publicly_accessible       = false
  parameter_group_name      = aws_db_parameter_group.this.name

  # Additive auth option -- the app keeps using its Secrets Manager password
  # today, this just makes IAM-based DB auth available without requiring an
  # app change. Performance Insights uses the 7-day free retention tier.
  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = var.kms_key_id != "" ? var.kms_key_id : null

  tags = merge(local.common_tags, {
    Name = format("%s-postgres-db", local.name_prefix)
  })
}

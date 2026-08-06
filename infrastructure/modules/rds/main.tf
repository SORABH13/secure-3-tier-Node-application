locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

resource "aws_db_parameter_group" "this" {
  name        = format("%s-postgres-parameters", local.name_prefix)
  family      = "postgres15"
  description = "Parameter group for node3tier PostgreSQL."

  tags = merge(local.common_tags, {
    Name = format("%s-postgres-parameters", local.name_prefix)
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
  identifier              = format("%s-db", local.name_prefix)
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids
  multi_az                = false
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = false
  publicly_accessible     = false
  parameter_group_name    = aws_db_parameter_group.this.name

  tags = merge(local.common_tags, {
    Name = format("%s-postgres-db", local.name_prefix)
  })
}

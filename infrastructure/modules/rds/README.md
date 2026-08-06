# RDS Module

This module provisions a PostgreSQL RDS instance for the toptal environment.

## Purpose

- Create a PostgreSQL instance inside private database subnets.
- Configure automated backups and deletion protection.
- Apply parameter group settings for production readiness.

## Inputs

- `project_name`
- `environment`
- `db_username`
- `db_password`
- `db_name`
- `db_instance_class`
- `allocated_storage`
- `engine_version`
- `backup_retention_period`
- `deletion_protection`
- `db_subnet_ids`
- `vpc_security_group_ids`
- `tags`

## Outputs

- `db_instance_identifier`
- `db_endpoint`
- `db_port`
- `db_subnet_group_name`

## Architecture Notes

The RDS instance is deployed in private database subnets with no public accessibility.
Backups are enabled and deletion protection is configurable for safe production operations.

# Secrets Manager Module

This module creates a Secrets Manager secret for PostgreSQL credentials.

## Purpose

- Store database username and password securely.
- Provide an ARN for ECS task access.

## Inputs

- `project_name`
- `environment`
- `db_username`
- `db_password`
- `db_name`
- `tags`

## Outputs

- `db_secret_arn`
- `db_secret_name`

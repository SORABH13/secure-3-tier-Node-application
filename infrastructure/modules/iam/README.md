# IAM Module

This module provisions IAM roles for ECS task execution and task runtime permissions.

## Purpose

- Create an ECS task execution role with ECR and CloudWatch permissions.
- Create a task role with Secrets Manager access for application runtime secrets.

## Inputs

- `project_name`
- `environment`
- `ecr_repository_arns`
- `secret_arns`
- `tags`

## Outputs

- `task_execution_role_arn`
- `task_execution_role_name`
- `task_role_arn`
- `task_role_name`

## Architecture Notes

The execution role uses the AWS managed ECS execution role policy.
The task role is scoped to read secrets and write logs using secure, least-privilege policies.

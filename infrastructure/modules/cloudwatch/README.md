# CloudWatch Module

This module creates CloudWatch resources for monitoring the toptal environment.

## Purpose

- Provision CloudWatch log groups.
- Create a dashboard for ECS, ALB, and RDS metrics.

## Inputs

- `project_name`
- `environment`
- `dashboard_name`
- `log_group_names`
- `cluster_name`
- `web_service_name`
- `api_service_name`
- `load_balancer_name`
- `target_group_name`
- `db_instance_identifier`
- `tags`

## Outputs

- `dashboard_name`
- `log_group_names`

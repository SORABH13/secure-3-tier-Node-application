# ECS Module

This module provisions ECS Fargate cluster resources for the toptal application.

## Purpose

- Create an ECS cluster.
- Register Web and API task definitions.
- Create Fargate services with rolling deployments.
- Enable service auto scaling based on CPU utilization.
- Provide CloudWatch log groups for both services.
- Configure private service discovery for the API service.

## Inputs

- `project_name`
- `environment`
- `cluster_name`
- `vpc_id`
- `subnet_ids`
- `web_security_group_id`
- `api_security_group_id`
- `task_execution_role_arn`
- `task_role_arn`
- `web_image`
- `api_image`
- `web_service_port`
- `api_service_port`
- `web_desired_count`
- `api_desired_count`
- `web_cpu`
- `web_memory`
- `api_cpu`
- `api_memory`
- `db_host`
- `db_name`
- `db_username`
- `db_secret_arn`
- `api_service_discovery_namespace`
- `tags`

## Outputs

- `cluster_name`
- `cluster_arn`
- `web_service_name`
- `api_service_name`
- `web_task_definition_arn`
- `api_task_definition_arn`
- `web_log_group_name`
- `api_log_group_name`
- `api_service_discovery_namespace`

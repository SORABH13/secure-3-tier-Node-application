# ALB Module

This module provisions an Application Load Balancer for the Web ECS service.

## Purpose

- Create a public ALB in the provided public subnets.
- Configure HTTP to HTTPS redirect.
- Create an HTTPS listener when a certificate ARN is provided.
- Create a target group for the Web ECS service.

## Inputs

- `project_name`
- `environment`
- `vpc_id`
- `subnet_ids`
- `security_group_id`
- `certificate_arn`
- `health_check_path`
- `target_group_port`
- `tags`

## Outputs

- `alb_arn`
- `alb_dns_name`
- `target_group_arn`
- `target_group_name`
- `https_listener_arn`

# Security Module

This module creates AWS Security Groups for the toptal secure architecture.

## Purpose

- Limit internet exposure to the ALB.
- Restrict Web ECS access to ALB only.
- Restrict API ECS access to Web ECS only.
- Restrict PostgreSQL access to API ECS only.

## Inputs

- `project_name`
- `environment`
- `vpc_id`
- `alb_ingress_cidrs`
- `alb_ingress_ipv6_cidrs`
- `tags`

## Outputs

- `alb_security_group_id`
- `web_security_group_id`
- `api_security_group_id`
- `postgres_security_group_id`

## Architecture Notes

The design follows least privilege:
- ALB is exposed to the internet.
- Web tasks only accept traffic from the ALB.
- API tasks only accept traffic from Web tasks.
- PostgreSQL is isolated behind API-only ingress.

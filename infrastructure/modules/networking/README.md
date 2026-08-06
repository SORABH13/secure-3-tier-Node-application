# Networking Module

This module creates the AWS networking foundation for the toptal production architecture.

## Purpose

- Provision a VPC with public, private application, and private database subnets.
- Configure internet connectivity through an Internet Gateway and NAT Gateway.
- Keep database subnets isolated from direct internet access.

## Inputs

- `project_name`
- `environment`
- `vpc_cidr`
- `availability_zones`
- `public_subnet_cidrs`
- `private_app_subnet_cidrs`
- `private_db_subnet_cidrs`
- `enable_dns_support`
- `enable_dns_hostnames`
- `tags`

## Outputs

- `vpc_id`
- `public_subnet_ids`
- `private_app_subnet_ids`
- `private_db_subnet_ids`
- `nat_gateway_id`
- `internet_gateway_id`

## Architecture Notes

- Two public subnets provide connectivity for the ALB and NAT Gateway.
- Two private application subnets host ECS tasks with outbound internet access via NAT.
- Two private database subnets host RDS instances without direct internet routes.
- Public and private route tables are separated for security and availability.

# Infrastructure

This directory contains the Terraform project structure for deploying the secure 3-tier Node.js application on AWS ECS Fargate.

## Structure

- `modules/` contains reusable Terraform modules for individual infrastructure domains.
- `environments/prod/` contains the production environment configuration and module wiring.

## Modules

- `networking`: VPC, subnets, route tables, and networking primitives.
- `security`: Security groups, NACLs, and network security constructs.
- `ecr`: Elastic Container Registry repositories and image lifecycle settings.
- `ecs`: ECS cluster, task definitions, and Fargate service orchestration.
- `alb`: Application Load Balancer, listeners, and target groups.
- `rds`: Amazon RDS database resources and subnet groups.
- `cloudwatch`: Metrics, logs, and alarms for observability.
- `cloudfront`: CDN distribution and cache behavior for the frontend.
- `iam`: IAM roles, policies, and service principals.
- `secrets-manager`: Secrets Manager secrets and secret rotation setup.

## Environments

- `environments/prod/` contains production-specific backend configuration, provider settings, and a `main.tf` that wires the modules together.

## Usage

1. Copy `environments/prod/terraform.tfvars.example` to `environments/prod/terraform.tfvars`.
2. Populate any environment-specific values.
3. Initialize Terraform in the environment directory:

```sh
cd infrastructure/environments/prod
terraform init
```

4. Validate the configuration:

```sh
terraform validate
```

5. Plan the deployment:

```sh
terraform plan
```

No AWS resources are provisioned by this scaffold until actual resource definitions are added to modules.

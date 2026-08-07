# Infrastructure

This directory contains the Terraform project structure for deploying the secure 3-tier Node.js application on AWS ECS Fargate.

## Structure

- `modules/` contains reusable Terraform modules for individual infrastructure domains.
- `environments/prod/` contains the production environment configuration and module wiring.

## Modules

- `networking`: VPC, public/private-app/private-db subnets across 2 AZs, one NAT Gateway per AZ, route tables.
- `security`: Security groups (ALB -> web -> api -> postgres, no wider access).
- `ecr`: Elastic Container Registry repositories with image scan-on-push and lifecycle policies.
- `ecs`: ECS cluster (Container Insights enabled), task definitions, Fargate services (web = CodeDeploy blue/green controller, api = ECS rolling), autoscaling.
- `alb`: Application Load Balancer, blue+green target groups, HTTP/HTTPS listeners.
- `rds`: RDS PostgreSQL, Multi-AZ, encrypted, private subnets only, deletion protection.
- `cloudwatch`: Dashboard, 10 CloudWatch alarms (ALB/ECS/RDS), SNS alerts topic.
- `cloudfront`: CDN distribution in front of the ALB, WAF web ACL attached.
- `iam`: ECS task/execution roles, plus GitHub Actions OIDC provider and two least-privilege deploy/terraform roles.
- `secrets-manager`: DB credentials secret (or reuses an existing one via `existing_secret_name`).
- `kms`: Customer-managed keys for RDS/Secrets Manager/Backup and for CloudTrail.
- `waf`: WAFv2 web ACL (AWS managed rule groups + per-IP rate limit) for CloudFront.
- `cloudtrail`: Multi-region audit trail to an encrypted, versioned, lifecycle-managed S3 bucket.
- `backup`: AWS Backup vault + daily plan + selection for RDS.
- `codedeploy`: CodeDeploy application/deployment group for Web blue/green + canary traffic shifting, with alarm-based auto-rollback.

See [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for the full diagram and rationale, and [../docs/DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md) for how to apply this for the first time (and what to expect if applying on top of an already-running environment).

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

6. Review the plan, then apply:

```sh
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

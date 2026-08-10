# Secure 3-Tier Node Application

A three-tier Node.js application (Web + API + PostgreSQL) with a production-grade AWS deployment: ECS Fargate, Multi-AZ RDS, CloudFront + WAF, CodeDeploy blue/green, and fully automated CI/CD -- all provisioned via Terraform.

## Project structure

- `app/api`: Backend API service (Express + PostgreSQL).
- `app/web`: Frontend web service (Express + Pug), calls the API server-side.
- `infrastructure/`: Terraform IaC for the AWS deployment (`modules/` + `environments/prod`).
- `.github/workflows/`: CI/CD pipelines (`app.yml` for the application, `infra.yml` for Terraform).
- `scripts/`: Operational scripts (RDS backup/restore, service start/stop/scale, Terraform output export, environment teardown).
- `docker-compose.yml`: Local/dev orchestration for PostgreSQL, API, and web.
- `docs/`: Architecture diagram, deployment guide, runbook, interview notes, and the architectural decision log.

## Local development (Docker Compose)

```sh
docker compose up --build
```

- Web app: `http://localhost:3000`
- API: `http://localhost:3001/api/status`
- PostgreSQL data persists in the named volume `postgres_data`.

Both app services run as a non-root user, use official Node LTS Alpine base images, and have container healthchecks. The web service reaches the API by Docker service name.

## AWS deployment

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full diagram and design rationale, and [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for how to provision it (first-time `terraform apply`, GitHub OIDC setup, ongoing deploys).

At a glance: CloudFront + WAF in front of an ALB, ECS Fargate web/API tasks in private subnets across 2 AZs, Multi-AZ RDS PostgreSQL in subnets with no internet route, per-AZ NAT Gateways, Secrets Manager + KMS for credentials, CloudWatch alarms + SNS for alerting, CloudTrail for audit logging, and AWS Backup for daily RDS recovery points.

## CI/CD

- `app.yml`: lint -> dependency + image security scan -> unit tests -> build/push to ECR -> deploy API (ECS rolling) + Web (CodeDeploy blue/green with canary traffic shifting and alarm-based auto-rollback) -> smoke test.
- `infra.yml`: tfsec -> `terraform plan` -> manual approval -> `terraform apply`.

Both currently authenticate to AWS via short-lived credentials stored as GitHub Actions secrets (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`). GitHub OIDC federation is fully built in Terraform (`infrastructure/modules/iam`, gated behind `enable_github_oidc`) but is currently blocked at the GitHub platform level -- `id-token` was never granted across 5+ real CI runs regardless of workflow permissions or IAM trust-policy shape. See [docs/DECISIONS.md](docs/DECISIONS.md) and [docs/INTERVIEW_NOTES.md](docs/INTERVIEW_NOTES.md) for the full story; re-enabling OIDC once that's resolved is a one-line change per credentials step (see [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)).

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) -- diagram and design rationale
- [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) -- how to provision and deploy
- [docs/RUNBOOK.md](docs/RUNBOOK.md) -- operational procedures per alarm/incident
- [docs/INTERVIEW_NOTES.md](docs/INTERVIEW_NOTES.md) -- talking points, likely questions, common mistakes avoided
- [docs/DECISIONS.md](docs/DECISIONS.md) / [docs/DOCKER_DECISIONS.md](docs/DOCKER_DECISIONS.md) -- architectural decision log
- [infrastructure/README.md](infrastructure/README.md) -- Terraform module reference

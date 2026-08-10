# Deployment Guide

## Prerequisites

- Terraform >= 1.2, AWS CLI v2, `jq`, Docker.
- An AWS account with the S3 state bucket (`toptal-yogi-project`) and DynamoDB lock table (`deploystar-state-locks`) already created (out of band -- state storage can't bootstrap itself from the config it stores).
- Push access to `SORABH13/secure-3-tier-Node-application` on GitHub.

## First-time infrastructure apply

```sh
cd infrastructure/environments/prod
cp terraform.tfvars.example terraform.tfvars   # then edit values for your account
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

Notes:
- There is no `db_password` variable -- Terraform generates it (`random_password.db` in `main.tf`) and writes it straight to Secrets Manager. Nobody ever types it.
- `terraform.tfvars` is gitignored on purpose (see `.gitignore`). Never commit it.

## ⚠️ Applying to an already-running environment

If you're applying this configuration on top of infrastructure that predates these changes (i.e. this repo's actual `prod` deployment), several changes have real, one-time operational impact. Review the plan output for these specifically before approving apply:

| Change | Effect | Mitigation |
|---|---|---|
| `random_password.db` replaces a static password variable | **Rotates the live RDS master password and Secrets Manager secret value immediately on apply.** | Expected and desired if the old password was ever exposed (e.g. committed to git). ECS tasks pick up the new secret automatically on their next deployment; no manual step needed. |
| `rds.multi_az: false -> true` | RDS instance modified in-place; AWS may briefly fail over during the change. | Low risk, in-place, no replacement. Apply outside peak traffic if possible. |
| NAT Gateway: 1 shared -> 1 per AZ | Old NAT Gateway/EIP/route table destroyed, new ones created. Private-subnet egress (ECR pulls, Secrets Manager calls) can see a brief interruption (up to a few minutes) while route tables cut over. | Apply during a low-traffic window; ECS tasks already running are unaffected (only *new* task placement/pulls would stall). |
| `ecs.aws_ecs_service.web` deployment_controller -> `CODE_DEPLOY` | **Forces replacement of the live Web ECS service** (deployment_controller is immutable). The service is destroyed and recreated attached to the same "blue" target group. | One-time migration cost for blue/green deploys going forward. Expect a short Web-tier interruption during this specific apply. Consider running this specific change in a maintenance window; API tier is unaffected. |
| RDS `kms_key_id` | **Not wired to the live instance on purpose** -- changing a KMS key on an existing encrypted RDS instance forces replacement (data loss risk if not paired with a snapshot/restore migration). The `kms` module's CMK is available (`module.kms.data_key_arn`) and used for Secrets Manager/Backup; migrating the existing RDS instance to it requires a deliberate snapshot-restore cutover -- see the Runbook. | Don't set `rds.kms_key_id` on the live instance without following that runbook procedure. |

If any of this is unacceptable for a live cutover, apply module-by-module with `-target` and schedule the ECS web replacement separately from the rest.

## Wiring up GitHub Actions (current: static credentials)

Both workflows currently authenticate with `aws-actions/configure-aws-credentials` reading three **repository secrets** under the `production` environment (Settings -> Environments -> production -> Secrets):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

These are short-lived STS credentials (an access key alone would have no session token), not a permanent IAM user key, but they still need manual rotation before they expire -- see `docs/RUNBOOK.md`/`docs/DECISIONS.md` for why this is the fallback rather than the target design.

Set an `environment: production` protection rule in GitHub (Settings -> Environments) requiring manual approval -- this is what gates `infra.yml`'s `terraform apply` job and `app.yml`'s deploy jobs, independent of which credential method is in use.

### Re-enabling OIDC (once the GitHub-side restriction lifts)

The IAM roles and OIDC provider are already provisioned by `infrastructure/modules/iam` (`enable_github_oidc = true` by default, scoped to `github_repository`). Swapping back is IAM-side already done -- it's purely a workflow change:

```sh
terraform output -raw github_app_deploy_role_arn
terraform output -raw github_terraform_role_arn
```

1. Set those two ARNs as **repository variables** (not secrets -- role ARNs aren't sensitive): `AWS_APP_DEPLOY_ROLE_ARN` (used by `app.yml`) and `AWS_TERRAFORM_ROLE_ARN` (used by `infra.yml`).
2. In both workflows, replace the `aws-access-key-id`/`aws-secret-access-key`/`aws-session-token` inputs on `configure-aws-credentials` with `role-to-assume: ${{ vars.AWS_APP_DEPLOY_ROLE_ARN }}` (or the terraform role, per job) and add `permissions: id-token: write` at the job level.
3. Confirm the run's "Permissions" panel actually lists `id-token` before trusting it -- this is exactly the check that failed repeatedly last time (see `docs/DECISIONS.md`).
4. Once confirmed working, delete the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` secrets.

## Ongoing deploys

- **App changes** (`app/**`): push to `master` -> `app.yml` lints, security-scans (npm audit + Trivy image scan), tests, builds/pushes images, deploys API via ECS rolling update, deploys Web via CodeDeploy blue/green (10% canary, 5 min bake, auto-rollback on the ALB 5xx/unhealthy-host alarms), then smoke-tests the live ALB.
- **Infra changes** (`infrastructure/**`): push to `master` -> `infra.yml` runs tfsec, `terraform plan`, waits for manual approval (GitHub environment protection), then applies.

## Destroying the environment

```sh
./scripts/destroy-infrastructure.sh --confirm
```

Disables RDS deletion protection first, then `terraform destroy` with `skip_final_snapshot=true` and `ecr_force_delete=true`. Irreversible -- only for full environment teardown.

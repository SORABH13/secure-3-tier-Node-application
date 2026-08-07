# Runbook

On-call procedures. Each one maps to a specific CloudWatch alarm defined in `infrastructure/modules/cloudwatch/main.tf`, published to the SNS topic (`toptal-prod-alerts`).

## Site is down / 5xx spike

**Alarm:** `toptal-prod-alb-5xx`

1. Check the dashboard: CloudWatch -> Dashboards -> `toptal-prod-dashboard` -- look at ALB request count, target CPU, healthy host count.
2. `aws ecs describe-services --cluster toptal-prod-cluster --services toptal-prod-web toptal-prod-api` -- check `runningCount` vs `desiredCount` and recent events.
3. If a deployment is in flight: check CodeDeploy (`aws deploy list-deployments --application-name toptal-prod-web --deployment-group-name toptal-prod-web`) -- it should already be auto-rolling-back on this exact alarm. If it's stuck, `aws deploy stop-deployment --deployment-id <id> --auto-rollback-enabled`.
4. If no deployment is in flight: check `/ecs/toptal-prod-web` and `/ecs/toptal-prod-api` CloudWatch Logs for application errors.

## Unhealthy targets

**Alarm:** `toptal-prod-alb-unhealthy-hosts`

1. `aws elbv2 describe-target-health --target-group-arn <web target group arn>` -- check the failure reason.
2. Common causes: task failing the `/stylesheets/style.css` health check (web container not starting), or a bad task definition (check the latest revision's image tag).
3. If caused by a bad deploy, CodeDeploy/ECS should already be rolling back automatically. If not, manually redeploy the last-known-good task definition: `aws ecs update-service --cluster toptal-prod-cluster --service toptal-prod-web --task-definition <previous-arn>`.

## Service running fewer tasks than desired

**Alarms:** `toptal-prod-web-running-tasks-low`, `toptal-prod-api-running-tasks-low`

1. `aws ecs describe-services ... --query 'services[0].events[:10]'` -- ECS logs placement failures here (e.g. no capacity, image pull failure, health check failure).
2. Check the task's stopped reason: `aws ecs describe-tasks --cluster toptal-prod-cluster --tasks <task-id>` -> `stoppedReason`.
3. Most common cause: `CannotPullContainerError` after a private-subnet NAT Gateway issue, or a Secrets Manager permission error on the execution role.

## Database: high CPU / low storage / low memory / high connections

**Alarms:** `toptal-prod-rds-cpu-high`, `toptal-prod-rds-free-storage-low`, `toptal-prod-rds-freeable-memory-low`, `toptal-prod-rds-connections-high`

1. RDS console -> Performance Insights on `toptal-prod-db` -- identify the offending query/session.
2. Connections climbing toward the limit is usually a connection-leak in the API tier (each API task should hold one long-lived `pg.Pool`, not open a pool per request -- verify `app/api/app.js` still does this).
3. Low storage: either grow `allocated_storage` via Terraform (`terraform apply -target=module.rds`) or investigate what's consuming space (e.g. unbounded table growth, WAL buildup).
4. This is a Multi-AZ instance: for capacity issues, a `terraform apply` with a bigger `db_instance_class` applies with a brief failover, not an outage.

## AZ failure

1. Multi-AZ RDS fails over automatically (DNS endpoint repoints to the standby, typically under 2 minutes) -- no manual action needed, just confirm via the `rds-cpu-high`/connection alarms clearing.
2. ECS services span both AZs with `desired_count >= 2` and autoscaling 2-4 -- ECS reschedules any lost tasks into the healthy AZ automatically.
3. Each AZ has its own NAT Gateway -- losing one AZ only affects that AZ's private-subnet egress, not the whole environment.

## Deployment failed

- **Web (CodeDeploy blue/green):** auto-rollback is configured for `DEPLOYMENT_FAILURE` and for the ALB alarms above tripping during the bake window. No action needed in most cases; verify via `aws deploy get-deployment --deployment-id <id>`.
- **API (ECS rolling):** `app.yml`'s `deploy-api` job captures the previous task definition ARN before deploying and rolls back to it automatically in its `if: failure()` step. Check the GitHub Actions run for the rollback log.

## Restore the database from backup

Two independent recovery paths:

1. **RDS automated backups / point-in-time recovery** (retained per `backup_retention_period`, default 7 days): `aws rds restore-db-instance-to-point-in-time`.
2. **AWS Backup daily recovery points** (retained `backup_retention_days`, default 35 days, in vault `toptal-prod-backup-vault`): restore via the AWS Backup console/CLI, or use `scripts/restore-rds.sh <snapshot-id> <new-instance-id> <db-subnet-group> <sg-id>` for a manual RDS snapshot.

Both always restore to a **new** RDS instance (RDS cannot restore in place). Cutover steps after either path:

1. Verify data on the restored instance.
2. Update the `password`/host in the `toptal-prod-db-credentials` Secrets Manager secret to point at the new endpoint (or re-run `terraform apply` if the endpoint is Terraform-managed).
3. `aws ecs update-service --cluster toptal-prod-cluster --service toptal-prod-api --force-new-deployment` so API tasks pick up the new connection string.

**RPO/RTO:** RPO is near-zero via PITR (continuous WAL shipping) or up to 24h via the AWS Backup daily job; RTO is the restore time (single-digit minutes for a `db.t4g.micro`) plus the manual cutover above.

## Migrating the live RDS instance to the customer-managed KMS key

Not automated on purpose -- `kms_key_id` is `ForceNew` on `aws_db_instance`, so applying it directly would destroy and recreate the database. To migrate safely:

1. Take a manual snapshot: `./scripts/backup-rds.sh toptal-prod-db`.
2. Copy the snapshot with the new KMS key: `aws rds copy-db-snapshot --source-db-snapshot-identifier <snap> --target-db-snapshot-identifier <snap>-kms --kms-key-id <module.kms.data_key_arn>`.
3. Restore a new instance from the copied (now CMK-encrypted) snapshot into the same subnet group/security groups.
4. Cut the API tier over to the new endpoint (same steps as the restore procedure above), verify, then decommission the old instance and import the new one into Terraform state (`terraform import`).

## Rotating the DB password

```sh
terraform taint random_password.db
terraform apply -var-file=terraform.tfvars
```

Terraform generates a new password, updates the RDS instance in place, and writes a new Secrets Manager secret version.

**Redeploy the API service afterward, always.** ECS resolves the `DBPASS` secret from Secrets Manager only at task launch time, not on already-running tasks -- so any rotation (this one, or an incidental one from an unrelated `terraform apply` that happens to touch `random_password.db`) leaves running API tasks holding the *old* password in memory, and every DB query starts failing with `password authentication failed` even though the apply itself reported success. This exact scenario happened during initial rollout of this pipeline (2026-08-07) and caused a real, if brief, outage before it was caught and redeployed manually.

`infra.yml`'s `terraform-apply` job now runs `aws ecs update-service --cluster toptal-prod-cluster --service toptal-prod-api --force-new-deployment` automatically after every apply (idempotent -- harmless when the secret didn't change), so this shouldn't recur via CI. Manual applies (`terraform apply` run locally) still need the same manual step:

```sh
aws ecs update-service --cluster toptal-prod-cluster --service toptal-prod-api --force-new-deployment
aws ecs wait services-stable --cluster toptal-prod-cluster --services toptal-prod-api
```

# Interview Talking Points

One section per feature area. Use these to explain *why*, not just *what*.

## High availability (Multi-AZ RDS + per-AZ NAT Gateways)

**How to explain it:** "The database runs Multi-AZ, so RDS maintains a synchronous standby in a second AZ and fails the DNS endpoint over automatically, typically in under two minutes, with zero data loss since replication is synchronous. Separately, I gave each AZ its own NAT Gateway instead of sharing one -- a shared NAT Gateway is a classic single point of failure that people miss: the compute tier looks multi-AZ, but if the NAT's AZ goes down, every private subnet loses internet egress, not just the one that failed."

**Likely questions:**
- *Why Multi-AZ instead of a read replica?* Multi-AZ is for availability (synchronous, automatic failover, same instance class, no query capacity benefit). A read replica is for read scaling (asynchronous, manual promotion, adds capacity). This workload needed HA, not read scaling, so Multi-AZ was the right primitive.
- *What's the actual RTO/RPO on failover?* RPO ~0 (synchronous replication). RTO is typically 60-120 seconds -- driven by DNS TTL and the standby promotion, not data transfer.
- *Why not Aurora?* Aurora's storage-layer replication and faster failover (sub-30s) would be the stronger answer at higher scale/traffic; for a `db.t4g.micro`-sized workload the standard RDS Multi-AZ cost/complexity tradeoff is more appropriate, and it's a straightforward `terraform apply -target` upgrade path later.

**Common mistake this avoids:** shipping single-AZ RDS with a "looks-HA" multi-AZ compute tier -- the database is almost always the actual single point of failure in these designs, and it's the one most candidates forget.

## CodeDeploy blue/green with canary traffic shifting (Web tier)

**How to explain it:** "The public-facing web service deploys through CodeDeploy blue/green using `ECSCanary10Percent5Minutes` -- 10% of traffic shifts to the new task set, CodeDeploy watches the ALB 5xx and unhealthy-host CloudWatch alarms for five minutes, and only then cuts over the rest. If those alarms trip during the bake window, it rolls back automatically -- no human has to notice and intervene."

**Likely questions:**
- *Why not blue/green for the API tier too?* CodeDeploy's ECS blue/green deployment type requires a load balancer with two target groups to shift traffic between. The API tier has no ALB -- it's internal-only, reached via Cloud Map service discovery -- so that traffic-shifting model doesn't apply. It uses ECS-native rolling deployment instead (100% minimum healthy percent), which is still zero-downtime, just without the canary bake window.
- *What triggers the rollback exactly?* Either `DEPLOYMENT_FAILURE` (tasks don't reach healthy) or the `alarm_configuration` block tripping `DEPLOYMENT_STOP_ON_ALARM` on the ALB 5xx/unhealthy-host alarms during the deployment.
- *Why keep the old target group around instead of deleting it?* It's the rollback target -- CodeDeploy needs both the blue and green target groups to exist to shift traffic back instantly if something goes wrong.

**Common mistake this avoids:** treating "ECS force-new-deployment" as if it were blue/green. It isn't -- it's a rolling update with no traffic-shifting control and no automated, alarm-driven rollback.

## GitHub OIDC: built, blocked at the platform level, honestly documented

**How to explain it:** "I built GitHub OIDC federation first -- an IAM OIDC provider plus two roles trusted via the token's `sub` claim, so CI never holds a static AWS credential. It's fully provisioned in Terraform (`infrastructure/modules/iam`, `enable_github_oidc`). In practice, GitHub never actually granted `id-token` to the job -- I confirmed that from the run's own Permissions panel, across 5+ real CI runs and three different trust-policy subject formats. That's a GitHub-platform-level restriction, not something fixable from workflow YAML or the IAM side. Rather than leave both pipelines blocked, I reverted the credentials step to short-lived STS credentials stored as Actions secrets, and left the OIDC roles in place so swapping back is a one-line change once the restriction lifts. I'd rather show a real, honestly-documented fallback than a diagram that claims OIDC is live when the actual workflow file says otherwise."

**Likely questions:**
- *So which one does CI actually use right now?* Static (STS session) credentials -- `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN` as GitHub Actions secrets. Check `.github/workflows/app.yml` and `infra.yml`'s `configure-aws-credentials` step -- that's the actual source of truth, not any doc claiming otherwise.
- *Why do you think `id-token` was never granted?* Likely an org/account-level Actions policy restriction on the GitHub side (this repo is on a personal account, not an org that explicitly enables OIDC federation for Actions). It's outside what this repo's workflow permissions or AWS-side trust policy can control.
- *Why two roles instead of one, once OIDC is re-enabled?* Least privilege -- the app-deploy role can only push to the two ECR repos and update the two ECS services; it has zero IAM/VPC/RDS access. The terraform role is broader (it manages the whole stack) but is still scoped to the specific AWS services this project uses, not `AdministratorAccess`, and its blast radius is bounded by GitHub's environment-protection manual approval gate before it ever runs `apply`.
- *What stops someone from forking the repo and assuming the role?* The trust policy's `sub` condition matches `repo:<owner>/<repo>:ref:refs/heads/master` exactly -- a fork has a different repo name, so its tokens fail the condition. (This only matters once OIDC is actually active.)
- *Isn't `iam:*` in the terraform role dangerous?* Yes, that's the honest tradeoff -- it's scoped to zero other AWS accounts and (once OIDC is active) gated behind OIDC + manual approval, but a compromise of that specific role is still high-impact. The stronger version of this answer for a larger org would be per-resource ARNs generated from Terraform plan output (e.g. via a policy-as-code tool), which is more setup than this assignment's scope justified.
- *Isn't the static-key fallback also a risk?* It's short-lived STS credentials, not a permanent IAM user key, and it's the honest interim state -- better to say "here's what's actually running and why" than to paper over a platform limitation neither Terraform nor the workflow YAML can fix.

**Common mistake this avoids:** documentation claiming a control (OIDC) is active when the actual pipeline config says otherwise -- an interviewer who reads `.github/workflows/*.yml` will catch that mismatch immediately, so the docs here describe what's actually running, not the aspirational end state.

## Secrets management (no plaintext passwords, ever)

**How to explain it:** "The DB master password isn't a Terraform variable a human types in -- it's generated by `random_password` at apply time, stored only in the encrypted S3 state backend and in Secrets Manager, and referenced by ECS tasks via the secret's ARN (`secrets` block in the task definition, not `environment`). No plaintext password exists anywhere in git, CI logs, or a `.tfvars` file."

**Likely questions:**
- *What if the password does leak (e.g. committed by accident)?* Rotation is a one-command fix: `terraform taint random_password.db && terraform apply` -- Terraform regenerates it, updates RDS in place, and writes a new Secrets Manager version. No manual password handling.
- *Why not use Secrets Manager's own rotation Lambda?* Would be the next iteration for a real production system with a compliance requirement for periodic rotation (e.g. every 90 days) -- this project rotates on-demand rather than on a schedule, which was the right scope for the assignment.

## Observability (CloudWatch alarms + SNS, not just a dashboard)

**How to explain it:** "A dashboard tells you what's wrong after you've already noticed something's wrong. I added ten CloudWatch alarms covering the failure modes that actually page someone -- ALB 5xx rate, unhealthy hosts, ECS CPU sustained past the autoscaling ceiling, running task count below desired (crash-looping), and RDS CPU/storage/memory/connections -- all fanning into a single SNS topic."

**Likely questions:**
- *Why not one alarm per metric per default threshold?* Thresholds are set relative to what "normal" looks like for this workload (e.g. CPU alarm fires at 85%, above the 50% autoscaling target -- it means scaling isn't keeping up, not that scaling is working as designed).
- *Real production alerting?* Swap the SNS email subscription for an HTTPS subscription pointed at a PagerDuty/Opsgenie integration URL -- one-line Terraform change, documented in the cloudwatch module.

## WAF, CloudTrail, and AWS Backup

**How to explain it:** "WAF sits on CloudFront (not the ALB) with AWS Managed Rule Groups for common exploits and known bad inputs, plus a per-IP rate limit -- blocking at the edge before traffic reaches the VPC. CloudTrail is a multi-region trail with log file validation, writing to a KMS-encrypted, versioned S3 bucket with a lifecycle policy -- that's the audit-log requirement. AWS Backup runs a real daily backup plan against RDS with its own vault and retention policy, independent of RDS's own automated backups, so there are two independent recovery paths."

**Likely questions:**
- *Why WAF on CloudFront and not the ALB?* CloudFront is the actual internet-facing edge in this design; putting WAF there blocks malicious requests before they ever reach the VPC, ALB, or compute. WAF on the ALB would still let CloudFront absorb the request first.
- *Isn't RDS's own `backup_retention_period` enough?* It's Point-in-Time Recovery, tied to the instance and not centrally managed. AWS Backup gives an independent, centrally-managed recovery point with its own retention and vault, which is the more defensible "daily backups" answer for an audit/compliance conversation.

## Terraform structure

**How to explain it:** "`modules/` holds one reusable module per AWS concern (networking, security groups, ALB, ECS, RDS, IAM, KMS, WAF, CloudTrail, Backup, CodeDeploy, CloudWatch); `environments/prod` wires them together with real values and owns the remote state (S3 + DynamoDB locking). Nothing in a module hardcodes an environment name -- a second environment is a new `environments/` directory that re-wires the same modules with different variables."

**Common mistake this avoids:** one giant `main.tf` with everything inline, which is impossible to review in a PR and impossible to safely target with `-target` during an incident.

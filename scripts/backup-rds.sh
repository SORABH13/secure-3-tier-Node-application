#!/usr/bin/env bash
#
# backup-rds.sh -- creates an on-demand RDS snapshot.
# Automated daily backups are handled by AWS Backup (see infrastructure/modules/backup),
# this script is for on-demand/manual snapshots (e.g. before a risky migration, or to
# demonstrate the backup mechanism during the interview).
#
# Usage: ./backup-rds.sh <db-instance-identifier>

set -euo pipefail

DB_INSTANCE_ID="${1:?Usage: $0 <db-instance-identifier>}"
TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
SNAPSHOT_ID="${DB_INSTANCE_ID}-manual-${TIMESTAMP}"

echo "Creating snapshot '${SNAPSHOT_ID}' of '${DB_INSTANCE_ID}'..."

aws rds create-db-snapshot \
  --db-instance-identifier "${DB_INSTANCE_ID}" \
  --db-snapshot-identifier "${SNAPSHOT_ID}"

echo "Waiting for snapshot to complete (this can take a few minutes)..."
aws rds wait db-snapshot-available --db-snapshot-identifier "${SNAPSHOT_ID}"

echo "Snapshot '${SNAPSHOT_ID}' completed successfully."

# Tag it so it's identifiable as a manual/on-demand backup vs the automated ones
SNAPSHOT_ARN=$(aws rds describe-db-snapshots \
  --db-snapshot-identifier "${SNAPSHOT_ID}" \
  --query 'DBSnapshots[0].DBSnapshotArn' --output text)

aws rds add-tags-to-resource \
  --resource-name "${SNAPSHOT_ARN}" \
  --tags Key=BackupType,Value=manual Key=CreatedBy,Value=backup-rds.sh

echo "Done. Snapshot ARN: ${SNAPSHOT_ARN}"

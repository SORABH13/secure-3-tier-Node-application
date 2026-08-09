#!/usr/bin/env bash
#
# restore-rds.sh -- restores an RDS instance from a snapshot into a NEW
# instance (RDS does not restore in-place; you always get a new instance,
# then cut your app over to it). This is deliberate: it never touches the
# live database, so this is safe to run against production for drills.
#
# Usage: ./restore-rds.sh <snapshot-id> <new-db-instance-identifier> <db-subnet-group> <vpc-security-group-id>

set -euo pipefail

SNAPSHOT_ID="${1:?Usage: $0 <snapshot-id> <new-instance-id> <db-subnet-group> <sg-id>}"
NEW_INSTANCE_ID="${2:?Missing new-instance-id}"
SUBNET_GROUP="${3:?Missing db-subnet-group}"
SG_ID="${4:?Missing security-group-id}"

echo "Restoring '${SNAPSHOT_ID}' into new instance '${NEW_INSTANCE_ID}'..."

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "${NEW_INSTANCE_ID}" \
  --db-snapshot-identifier "${SNAPSHOT_ID}" \
  --db-subnet-group-name "${SUBNET_GROUP}" \
  --vpc-security-group-ids "${SG_ID}" \
  --no-publicly-accessible \
  --no-multi-az

echo "Waiting for restored instance to become available (several minutes)..."
aws rds wait db-instance-available --db-instance-identifier "${NEW_INSTANCE_ID}"

ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "${NEW_INSTANCE_ID}" \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "Restore complete."
echo "New instance endpoint: ${ENDPOINT}"
echo ""
echo "Next steps to cut over:"
echo "  1. Verify data on the restored instance."
echo "  2. Update the DBHOST secret in Secrets Manager to point at: ${ENDPOINT}"
echo "  3. Redeploy the api service (aws ecs update-service --force-new-deployment)"
echo "     so tasks pick up the new connection string."

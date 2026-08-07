#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--confirm" || "$#" -ne 1 ]]; then
  echo "This permanently deletes all Terraform-managed production resources, including ECR images, without an RDS final snapshot."
  echo "Run: ./scripts/destroy-infrastructure.sh --confirm"
  exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TF_DIR="$SCRIPT_DIR/../infrastructure/environments/prod"

cd "$TF_DIR"
terraform init -input=false

# Deletion protection must be disabled before Terraform can delete an existing DB instance.
if terraform state list | grep -qx "module.rds.aws_db_instance.this"; then
  terraform apply \
    -auto-approve \
    -input=false \
    -target=module.rds.aws_db_instance.this \
    -var-file=terraform.tfvars \
    -var="deletion_protection=false"
fi

terraform destroy \
  -auto-approve \
  -input=false \
  -var-file=terraform.tfvars \
  -var="deletion_protection=false" \
  -var="skip_final_snapshot=true" \
  -var="ecr_force_delete=true"

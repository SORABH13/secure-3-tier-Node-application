#!/usr/bin/env bash
set -euo pipefail

# Exports Terraform outputs for the prod environment to a JSON file
cd "$(dirname "$0")/.." || exit 1
cd infrastructure/environments/prod

TF_DATA_DIR="$(pwd)/.terraform_data" terraform output -json > terraform-outputs.json
echo "Wrote terraform-outputs.json"

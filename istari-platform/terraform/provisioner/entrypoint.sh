#!/usr/bin/env bash
set -euo pipefail

cd /terraform

# Kubernetes is the only supported backend — no external cloud state infra required.
cat > backend.tf <<'EOF'
terraform {
  backend "kubernetes" {}
}
EOF

# TF_CLI_CONFIG_FILE (set in the image) points at a baked-in provider mirror — no network call.
terraform init -input=false \
  -backend-config="secret_suffix=${TF_BACKEND_SECRET_SUFFIX}" \
  -backend-config="namespace=${TF_BACKEND_NAMESPACE}" \
  -backend-config="in_cluster_config=true"

if [ "${TF_PLAN_ONLY:-false}" = "true" ]; then
  terraform plan -input=false -var-file=terraform.tfvars
  exit 0
fi

terraform apply -input=false -auto-approve -var-file=terraform.tfvars

#!/usr/bin/env bash
set -euo pipefail

cd /terraform

# Selects backend-${TF_BACKEND_TYPE}.tf.tmpl, writes it as backend.tf, and builds
# TF_INIT_BACKEND_CONFIG_ARGS.
# shellcheck disable=SC1091 # shipped alongside this script, not present at lint time
source ./backend-init.sh

# TF_CLI_CONFIG_FILE (set in the image) points at a baked-in provider mirror — no network call.
# shellcheck disable=SC2086 # intentionally unquoted: a space-separated list of -backend-config= flags
terraform init -input=false ${TF_INIT_BACKEND_CONFIG_ARGS}

if [ "${TF_PLAN_ONLY:-false}" = "true" ]; then
  terraform plan -input=false -var-file=terraform.tfvars
  exit 0
fi

terraform apply -input=false -auto-approve -var-file=terraform.tfvars

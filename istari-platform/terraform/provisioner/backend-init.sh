#!/usr/bin/env bash
set -euo pipefail

case "${TF_BACKEND_TYPE}" in
  kubernetes)
    cp backend-kubernetes.tf.tmpl backend.tf
    TF_INIT_BACKEND_CONFIG_ARGS="-backend-config=secret_suffix=${TF_BACKEND_KUBERNETES_SECRET_SUFFIX} -backend-config=namespace=${TF_BACKEND_KUBERNETES_NAMESPACE} -backend-config=in_cluster_config=true"
    ;;
  s3)
    cp backend-s3.tf.tmpl backend.tf
    # use_lockfile=true: native S3 state locking (Terraform >=1.10, and this image is 1.16.1),
    # so no separate DynamoDB lock table is required.
    TF_INIT_BACKEND_CONFIG_ARGS="-backend-config=bucket=${TF_BACKEND_S3_BUCKET} -backend-config=key=${TF_BACKEND_S3_KEY} -backend-config=region=${TF_BACKEND_S3_REGION} -backend-config=use_lockfile=true"
    ;;
  azurerm)
    cp backend-azurerm.tf.tmpl backend.tf
    # azurerm backend locks natively via a blob lease — no extra config needed for locking.
    TF_INIT_BACKEND_CONFIG_ARGS="-backend-config=storage_account_name=${TF_BACKEND_AZURERM_STORAGE_ACCOUNT_NAME} -backend-config=container_name=${TF_BACKEND_AZURERM_CONTAINER_NAME} -backend-config=key=${TF_BACKEND_AZURERM_KEY}"
    ;;
  gcs)
    cp backend-gcs.tf.tmpl backend.tf
    # gcs backend locks natively via object generation — no extra config needed for locking.
    TF_INIT_BACKEND_CONFIG_ARGS="-backend-config=bucket=${TF_BACKEND_GCS_BUCKET} -backend-config=prefix=${TF_BACKEND_GCS_PREFIX}"
    ;;
  *)
    echo "unknown TF_BACKEND_TYPE: ${TF_BACKEND_TYPE} (want kubernetes|s3|azurerm|gcs)" >&2
    exit 1
    ;;
esac

export TF_INIT_BACKEND_CONFIG_ARGS

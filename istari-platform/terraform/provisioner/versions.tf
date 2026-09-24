# Must stay byte-identical to this file's counterpart in the repo that builds the provisioner's
# container image (and .terraform.lock.hcl too) — no shared-package mechanism between the two.
#
# No backend block here — the entrypoint script writes the matching backend "<type>" {} stanza
# at runtime, before `terraform init`.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Deliberately empty — auto-detects in-cluster config via KUBERNETES_SERVICE_HOST/_PORT and reads
# the mounted ServiceAccount token internally. Do not set host/cluster_ca_certificate/token via
# file() — that's eagerly evaluated and fails `terraform validate` outside a pod.
provider "kubernetes" {}

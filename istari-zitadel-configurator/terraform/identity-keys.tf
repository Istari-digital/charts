# Identity-service key material (DPLAT-653).
#
# Ports the helm-stack pattern (istari-services/v2-secrets.tf, shipped for
# DPLAT-602/DPLAT-513) to the customer configurator, so no manual
# gen-signing-key / gen-client-credentials / openssl steps remain. Blob shapes
# ({clientId,keyId,key}, ECDSA P-384 PKCS#8 PEM) are exactly what the
# identity-service's register-client / register-agent tools parse.
#
# Private blobs go only to the owning service's secret; the identity-service
# receives public-only blobs. Rotation: bump the matching
# identity_key_rotation_* variable — terraform_data + replace_triggered_by
# recreates just that credential.
#
# This file must not reference zitadel_* resources: the standalone test
# harness (tests/test-identity-keys.sh) applies it without a Zitadel.

# ---- rotation triggers -------------------------------------------------

resource "terraform_data" "identity_signing_key_rotation" {
  input = var.identity_key_rotation_signing_key
}

resource "terraform_data" "identity_token_encryption_key_rotation" {
  input = var.identity_key_rotation_token_encryption_key
}

resource "terraform_data" "identity_registry_client_rotation" {
  input = var.identity_key_rotation_registry_client
}

resource "terraform_data" "identity_scs_agent_rotation" {
  input = var.identity_key_rotation_scs_agent
}

resource "terraform_data" "identity_mcp_client_secret_rotation" {
  input = var.identity_key_rotation_mcp_client_secret
}

# ---- signing + token-encryption keys (identity_generate_keys) ----------

# ECDSA P-384 is the CNSA 2.0 algorithm gen-signing-key produces and
# ValidateSigningKey prefers.
resource "tls_private_key" "identity_signing_key" {
  count = var.identity_generate_keys ? 1 : 0

  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    replace_triggered_by = [terraform_data.identity_signing_key_rotation]
  }
}

resource "random_id" "identity_signing_key_id_suffix" {
  count = var.identity_generate_keys ? 1 : 0

  byte_length = 4

  lifecycle {
    replace_triggered_by = [terraform_data.identity_signing_key_rotation]
  }
}

# 32 bytes = AES-256; the identity-service rejects any other length.
resource "random_bytes" "identity_token_encryption_key" {
  count = var.identity_generate_keys ? 1 : 0

  length = 32

  lifecycle {
    replace_triggered_by = [terraform_data.identity_token_encryption_key_rotation]
  }
}

# ---- registry-service client (identity_client_integration_enabled) -----

# Must be ECDSA P-384: the registry signs an ES384 private_key_jwt assertion
# and the identity-service rejects any non-P-384 client key (isECP384Secret).
resource "tls_private_key" "identity_registry_client" {
  count = var.identity_client_integration_enabled ? 1 : 0

  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    replace_triggered_by = [terraform_data.identity_registry_client_rotation]
  }
}

resource "random_id" "identity_registry_client_id_suffix" {
  count = var.identity_client_integration_enabled ? 1 : 0

  byte_length = 4

  lifecycle {
    replace_triggered_by = [terraform_data.identity_registry_client_rotation]
  }
}

resource "random_id" "identity_registry_key_id_suffix" {
  count = var.identity_client_integration_enabled ? 1 : 0

  byte_length = 4

  lifecycle {
    replace_triggered_by = [terraform_data.identity_registry_client_rotation]
  }
}

# ---- frontend public client (id only, no key material) -----------------

resource "random_id" "identity_frontend_client_id_suffix" {
  count = var.identity_client_integration_enabled ? 1 : 0

  byte_length = 4
}

# ---- MCP public client (id + secret; secret semantics may change under
# DPLAT-647) --------------------------------------------------------------

resource "random_id" "identity_mcp_client_id_suffix" {
  count = var.identity_client_integration_enabled && var.mcp_enabled ? 1 : 0

  byte_length = 4
}

resource "random_password" "identity_mcp_client_secret" {
  count = var.identity_client_integration_enabled && var.mcp_enabled ? 1 : 0

  length  = 48
  special = false

  lifecycle {
    replace_triggered_by = [terraform_data.identity_mcp_client_secret_rotation]
  }
}

# ---- secure-connection-service agent credential -------------------------

# Same P-384 requirement (register-agent / internal/keys PublicKeyAndAlg).
resource "tls_private_key" "identity_scs_agent" {
  count = var.identity_client_integration_enabled ? 1 : 0

  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  lifecycle {
    replace_triggered_by = [terraform_data.identity_scs_agent_rotation]
  }
}

resource "random_id" "identity_scs_agent_client_id_suffix" {
  count = var.identity_client_integration_enabled ? 1 : 0

  byte_length = 4

  lifecycle {
    replace_triggered_by = [terraform_data.identity_scs_agent_rotation]
  }
}

resource "random_id" "identity_scs_agent_key_id_suffix" {
  count = var.identity_client_integration_enabled ? 1 : 0

  byte_length = 4

  lifecycle {
    replace_triggered_by = [terraform_data.identity_scs_agent_rotation]
  }
}

# ---- assembled blobs -----------------------------------------------------

locals {
  identity_signing_key_blob = var.identity_generate_keys ? base64encode(jsonencode({
    keyId = "signing-key-${random_id.identity_signing_key_id_suffix[0].hex}"
    key   = tls_private_key.identity_signing_key[0].private_key_pem_pkcs8
  })) : ""

  identity_token_encryption_key = var.identity_generate_keys ? random_bytes.identity_token_encryption_key[0].base64 : ""

  identity_registry_client_id = var.identity_client_integration_enabled ? "registry-${random_id.identity_registry_client_id_suffix[0].hex}" : ""
  identity_registry_key_id    = var.identity_client_integration_enabled ? "registry-key-${random_id.identity_registry_key_id_suffix[0].hex}" : ""

  identity_registry_private_blob = var.identity_client_integration_enabled ? base64encode(jsonencode({
    clientId = local.identity_registry_client_id
    keyId    = local.identity_registry_key_id
    key      = tls_private_key.identity_registry_client[0].private_key_pem_pkcs8
  })) : ""

  identity_registry_public_blob = var.identity_client_integration_enabled ? base64encode(jsonencode({
    clientId = local.identity_registry_client_id
    keyId    = local.identity_registry_key_id
    key      = tls_private_key.identity_registry_client[0].public_key_pem
  })) : ""

  identity_frontend_client_id = var.identity_client_integration_enabled ? "frontend-${random_id.identity_frontend_client_id_suffix[0].hex}" : ""

  identity_mcp_enabled       = var.identity_client_integration_enabled && var.mcp_enabled
  identity_mcp_client_id     = local.identity_mcp_enabled ? "mcp-${random_id.identity_mcp_client_id_suffix[0].hex}" : ""
  identity_mcp_client_secret = local.identity_mcp_enabled ? random_password.identity_mcp_client_secret[0].result : ""

  identity_scs_agent_client_id = var.identity_client_integration_enabled ? "secure-connection-${random_id.identity_scs_agent_client_id_suffix[0].hex}" : ""
  identity_scs_agent_key_id    = var.identity_client_integration_enabled ? "secure-connection-key-${random_id.identity_scs_agent_key_id_suffix[0].hex}" : ""

  identity_scs_agent_private_blob = var.identity_client_integration_enabled ? base64encode(jsonencode({
    clientId = local.identity_scs_agent_client_id
    keyId    = local.identity_scs_agent_key_id
    key      = tls_private_key.identity_scs_agent[0].private_key_pem_pkcs8
  })) : ""

  identity_scs_agent_public_blob = var.identity_client_integration_enabled ? base64encode(jsonencode({
    clientId = local.identity_scs_agent_client_id
    keyId    = local.identity_scs_agent_key_id
    key      = tls_private_key.identity_scs_agent[0].public_key_pem
  })) : ""
}

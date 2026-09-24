locals {
  # Explicit per-client override always wins; otherwise derive from main_domain.
  frontend_redirect_uri = var.frontend_redirect_uri != "" ? var.frontend_redirect_uri : (
    var.main_domain != "" ? "https://${var.main_domain}" : ""
  )
  mcp_redirect_uri = var.mcp_redirect_uri != "" ? var.mcp_redirect_uri : (
    var.main_domain != "" ? "https://mcp.${var.main_domain}/auth/callback" : ""
  )

  # identity-service's own public URL, written into every enabled client's secret.
  identity_service_url = var.identity_service_url != "" ? var.identity_service_url : (
    var.main_domain != "" ? "https://identity.${var.main_domain}" : ""
  )

  frontend_all_redirect_uris = concat(
    local.frontend_redirect_uri != "" ? [local.frontend_redirect_uri] : [],
    var.frontend_extra_redirect_uris,
  )
  mcp_all_redirect_uris = concat(
    local.mcp_redirect_uri != "" ? [local.mcp_redirect_uri] : [],
    var.mcp_extra_redirect_uris,
  )

  registry_client_id          = var.registry_enabled ? "registry-${random_id.registry_client_id_suffix[0].hex}" : ""
  registry_key_id             = var.registry_enabled ? "registry-key-${random_id.registry_key_id_suffix[0].hex}" : ""
  secure_connection_client_id = var.secure_connection_enabled ? "secure-connection-${random_id.secure_connection_client_id_suffix[0].hex}" : ""
  secure_connection_key_id    = var.secure_connection_enabled ? "secure-connection-key-${random_id.secure_connection_key_id_suffix[0].hex}" : ""
  frontend_client_id          = var.frontend_enabled ? "frontend-${random_id.frontend_client_id_suffix[0].hex}" : ""
  mcp_client_id               = var.mcp_enabled ? "mcp-${random_id.mcp_client_id_suffix[0].hex}" : ""

  service_clients = concat(
    var.registry_enabled ? [{
      serviceId         = "registry"
      kind              = "service"
      canListPrincipals = true
      credential = base64encode(jsonencode({
        clientId = local.registry_client_id
        keyId    = local.registry_key_id
        key      = tls_private_key.registry[0].public_key_pem
      }))
    }] : [],
    var.secure_connection_enabled ? [{
      serviceId         = "secure-connection"
      kind              = "service"
      canListPrincipals = false
      credential = base64encode(jsonencode({
        clientId = local.secure_connection_client_id
        keyId    = local.secure_connection_key_id
        key      = tls_private_key.secure_connection[0].public_key_pem
      }))
    }] : [],
    var.frontend_enabled ? [{
      serviceId    = "frontend"
      kind         = "public"
      clientId     = local.frontend_client_id
      redirectUris = local.frontend_all_redirect_uris
    }] : [],
    var.mcp_enabled ? [{
      serviceId    = "mcp"
      kind         = "public"
      clientId     = local.mcp_client_id
      redirectUris = local.mcp_all_redirect_uris
    }] : [],
  )
}


# ---- registry (kind: service) ----
resource "random_id" "registry_client_id_suffix" {
  count       = var.registry_enabled ? 1 : 0
  byte_length = 4
}
resource "random_id" "registry_key_id_suffix" {
  count       = var.registry_enabled ? 1 : 0
  byte_length = 4
}
resource "tls_private_key" "registry" {
  count = var.registry_enabled ? 1 : 0
  # Must be ECDSA P-384 — identity rejects any non-P-384 client key.
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
resource "kubernetes_secret_v1" "registry" {
  count = var.registry_enabled ? 1 : 0
  metadata {
    name      = var.registry_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = {
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_CREDENTIALS = base64encode(jsonencode({
      clientId = local.registry_client_id
      keyId    = local.registry_key_id
      key      = tls_private_key.registry[0].private_key_pem_pkcs8
    }))
    # Legacy + DPLAT-602 names for the same "identity is on" signal — both emitted for compat.
    FILE_SERVICE_FEATURE_FLAGS__IDENTITY_ROUTER_ENABLED = "true"
    FILE_SERVICE_IDENTITY_ROUTER_URL                    = local.identity_service_url
    ISTARI_DIGITAL_IDENTITY_SERVICE_ENABLED             = "true"
  }
}

# ---- secure-connection-service (kind: service, following registry's exact parameters) ----
resource "random_id" "secure_connection_client_id_suffix" {
  count       = var.secure_connection_enabled ? 1 : 0
  byte_length = 4
}
resource "random_id" "secure_connection_key_id_suffix" {
  count       = var.secure_connection_enabled ? 1 : 0
  byte_length = 4
}
resource "tls_private_key" "secure_connection" {
  count       = var.secure_connection_enabled ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
resource "kubernetes_secret_v1" "secure_connection" {
  count = var.secure_connection_enabled ? 1 : 0
  metadata {
    name      = var.secure_connection_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = {
    # SCS is kind:service, not an agent — no legacy ISTARI_DIGITAL_IDENTITY_ROUTER_AGENT_KEY name.
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_CREDENTIALS = base64encode(jsonencode({
      clientId = local.secure_connection_client_id
      keyId    = local.secure_connection_key_id
      key      = tls_private_key.secure_connection[0].private_key_pem_pkcs8
    }))
    ISTARI_DIGITAL_IDENTITY_ROUTER_ENABLED = "true"
    ISTARI_DIGITAL_IDENTITY_ROUTER_URL     = local.identity_service_url
  }
}

# ---- frontend (kind: public / PKCE — no keypair) ----
resource "random_id" "frontend_client_id_suffix" {
  count       = var.frontend_enabled ? 1 : 0
  byte_length = 4
}
resource "kubernetes_secret_v1" "frontend" {
  count = var.frontend_enabled ? 1 : 0
  metadata {
    name      = var.frontend_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = {
    # Legacy + DPLAT-602 names emitted together for compat.
    VITE_IDENTITY_SERVICE_CLIENT_ID              = local.frontend_client_id
    VITE_IDENTITY_ROUTER_CLIENT_ID               = local.frontend_client_id
    VITE_IDENTITY_ROUTER_ENABLED                 = "true"
    VITE_IDENTITY_ROUTER_AUTHORITY               = local.identity_service_url
    VITE_ISTARI_DIGITAL_IDENTITY_SERVICE_ENABLED = "true"
  }
}

# ---- mcp (kind: public / PKCE — no keypair, but fastmcp wants a non-empty client_secret) ----
resource "random_id" "mcp_client_id_suffix" {
  count       = var.mcp_enabled ? 1 : 0
  byte_length = 4
}
resource "random_password" "mcp_client_secret" {
  count   = var.mcp_enabled ? 1 : 0
  length  = 32
  special = true
}
resource "kubernetes_secret_v1" "mcp" {
  count = var.mcp_enabled ? 1 : 0
  metadata {
    name      = var.mcp_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = {
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_ID = local.mcp_client_id
    # fastmcp requires this non-empty; identity-service doesn't verify it for a PKCE client.
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_SECRET = random_password.mcp_client_secret[0].result
    ISTARI_DIGITAL_IDENTITY_SERVICE_ENABLED       = "true"
  }
}

# ---- identity's serviceClients Secret — what provision-service-clients mounts ----
resource "kubernetes_secret_v1" "identity_service_clients" {
  count = length(local.service_clients) > 0 ? 1 : 0
  metadata {
    name      = var.identity_service_clients_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = {
    "serviceClients.yaml" = yamlencode({ serviceClients = local.service_clients })
  }

  # lifecycle.precondition hard-fails plan/apply; `check`/`assert` only ever warns.
  lifecycle {
    precondition {
      condition     = !var.frontend_enabled || length(local.frontend_all_redirect_uris) > 0
      error_message = "frontend is enabled but no redirect URI could be resolved — set provisioner.clients.frontend.redirectUri or provisioner.mainDomain."
    }
    precondition {
      condition     = !var.mcp_enabled || length(local.mcp_all_redirect_uris) > 0
      error_message = "mcp is enabled but no redirect URI could be resolved — set provisioner.clients.mcp.redirectUri or provisioner.mainDomain."
    }
    precondition {
      condition     = local.identity_service_url != ""
      error_message = "at least one client is enabled but the identity-service URL could not be resolved — set provisioner.identityServiceUrl or provisioner.mainDomain."
    }
  }
}

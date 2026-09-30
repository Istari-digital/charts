# ---- reuse of existing credentials ----
# An upgrade reuses the client ids and keys already in the cluster: this provisioner's own
# earlier Secrets first, then the adopt_* sources. Only a client with neither is minted.
locals {
  any_client_enabled = var.registry_enabled || var.frontend_enabled || var.mcp_enabled

  registry_candidates = concat(
    [{ name = var.registry_secret_name, key = "ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_CREDENTIALS" }],
    var.adopt_existing ? var.adopt_registry_sources : [],
  )
  frontend_candidates = concat(
    [{ name = var.frontend_secret_name, key = "VITE_IDENTITY_SERVICE_CLIENT_ID" }],
    var.adopt_existing ? var.adopt_frontend_sources : [],
  )
  mcp_candidates = concat(
    [{ name = var.mcp_secret_name, key = "ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_ID" }],
    var.adopt_existing ? var.adopt_mcp_sources : [],
  )
  mcp_secret_candidates = concat(
    [{ name = var.mcp_secret_name, key = "ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_SECRET" }],
    var.adopt_existing ? var.adopt_mcp_secret_sources : [],
  )
  identity_service_url_candidates = concat(
    [
      { name = var.registry_secret_name, key = "FILE_SERVICE_IDENTITY_ROUTER_URL" },
      { name = var.frontend_secret_name, key = "VITE_IDENTITY_ROUTER_AUTHORITY" },
    ],
    var.adopt_existing ? var.adopt_identity_service_url_sources : [],
  )
  redirect_uri_secret_names = compact([
    var.identity_platform_clients_secret_name,
    var.adopt_existing ? var.adopt_redirect_uris_secret_name : "",
  ])

  adopt_secret_names = local.any_client_enabled ? toset(concat(
    [for c in concat(local.registry_candidates, local.frontend_candidates,
    local.mcp_candidates, local.mcp_secret_candidates, local.identity_service_url_candidates) : c.name],
    local.redirect_uri_secret_names,
  )) : toset([])

  # First non-empty value among a candidate list; "" when none holds one.
  registry_blob_raw               = try(compact([for c in local.registry_candidates : try(data.kubernetes_secret_v1.existing[c.name].data[c.key], "")])[0], "")
  existing_frontend_client_id     = nonsensitive(try(compact([for c in local.frontend_candidates : try(data.kubernetes_secret_v1.existing[c.name].data[c.key], "")])[0], ""))
  existing_mcp_client_id          = nonsensitive(try(compact([for c in local.mcp_candidates : try(data.kubernetes_secret_v1.existing[c.name].data[c.key], "")])[0], ""))
  existing_mcp_client_secret      = try(compact([for c in local.mcp_secret_candidates : try(data.kubernetes_secret_v1.existing[c.name].data[c.key], "")])[0], "")
  existing_identity_service_url   = nonsensitive(try(compact([for c in local.identity_service_url_candidates : try(data.kubernetes_secret_v1.existing[c.name].data[c.key], "")])[0], ""))
  existing_frontend_redirect_uris = nonsensitive(try(compact([for n in local.redirect_uri_secret_names : try(data.kubernetes_secret_v1.existing[n].data["ISTARI_DIGITAL_IDENTITY_SERVICE_FRONTEND_REDIRECT_URIS"], "")])[0], ""))
  existing_mcp_redirect_uris      = nonsensitive(try(compact([for n in local.redirect_uri_secret_names : try(data.kubernetes_secret_v1.existing[n].data["ISTARI_DIGITAL_IDENTITY_SERVICE_MCP_REDIRECT_URIS"], "")])[0], ""))

  registry_blob       = try(jsondecode(base64decode(local.registry_blob_raw)), null)
  registry_adopted    = var.registry_enabled && nonsensitive(local.registry_blob_raw != "")
  frontend_adopted    = var.frontend_enabled && local.existing_frontend_client_id != ""
  mcp_adopted         = var.mcp_enabled && local.existing_mcp_client_id != ""
  registry_blob_valid = !local.registry_adopted || nonsensitive(can(local.registry_blob.clientId) && can(local.registry_blob.keyId) && can(regex("PRIVATE KEY", local.registry_blob.key)))
}

# A missing Secret reads as null data, not an error (hashicorp/kubernetes 2.38.0, as locked).
data "kubernetes_secret_v1" "existing" {
  for_each = local.adopt_secret_names
  metadata {
    name      = each.key
    namespace = var.namespace
  }
}

data "tls_public_key" "registry_adopted" {
  count           = local.registry_adopted && local.registry_blob_valid ? 1 : 0
  private_key_pem = local.registry_blob.key
}

locals {
  # Explicit per-client override always wins; otherwise derive from main_domain.
  frontend_redirect_uri = var.frontend_redirect_uri != "" ? var.frontend_redirect_uri : (
    var.main_domain != "" ? "https://${var.main_domain}" : ""
  )
  mcp_redirect_uri = var.mcp_redirect_uri != "" ? var.mcp_redirect_uri : (
    var.main_domain != "" ? "https://mcp.${var.main_domain}/auth/callback" : ""
  )
  # Configured URIs win; with none, the URIs already registered are kept.
  frontend_configured_uris = local.frontend_redirect_uri != "" || length(var.frontend_extra_redirect_uris) > 0
  mcp_configured_uris      = local.mcp_redirect_uri != "" || length(var.mcp_extra_redirect_uris) > 0

  # identity-service's own public URL. Consumed by registry and frontend's secrets -- NOT mcp's,
  # which derives its issuer from apiGateway.apiUrl instead. secure-connection-service is not
  # provisioned through this mechanism (see helm-stack's identity-service-env generation) --
  # its credential/registration model isn't supported here.
  identity_service_url = var.identity_service_url != "" ? var.identity_service_url : (
    var.main_domain != "" ? "https://identity.${var.main_domain}" : local.existing_identity_service_url
  )
  identity_service_url_required = var.registry_enabled || var.frontend_enabled

  frontend_all_redirect_uris = local.frontend_configured_uris ? concat(
    local.frontend_redirect_uri != "" ? [local.frontend_redirect_uri] : [],
    var.frontend_extra_redirect_uris,
  ) : compact(split(",", local.existing_frontend_redirect_uris))
  mcp_all_redirect_uris = local.mcp_configured_uris ? concat(
    local.mcp_redirect_uri != "" ? [local.mcp_redirect_uri] : [],
    var.mcp_extra_redirect_uris,
  ) : compact(split(",", local.existing_mcp_redirect_uris))

  registry_client_id = !var.registry_enabled ? "" : (
    local.registry_adopted ? nonsensitive(try(local.registry_blob.clientId, "")) : "registry-${random_id.registry_client_id_suffix[0].hex}"
  )
  registry_key_id = !var.registry_enabled ? "" : (
    local.registry_adopted ? nonsensitive(try(local.registry_blob.keyId, "")) : "registry-key-${random_id.registry_key_id_suffix[0].hex}"
  )
  registry_private_key_pem = !var.registry_enabled ? "" : (
    local.registry_adopted ? try(local.registry_blob.key, "") : tls_private_key.registry[0].private_key_pem_pkcs8
  )
  registry_public_key_pem = !var.registry_enabled ? "" : (
    local.registry_adopted ? try(data.tls_public_key.registry_adopted[0].public_key_pem, "") : tls_private_key.registry[0].public_key_pem
  )
  frontend_client_id = !var.frontend_enabled ? "" : (
    local.frontend_adopted ? local.existing_frontend_client_id : "frontend-${random_id.frontend_client_id_suffix[0].hex}"
  )
  mcp_client_id = !var.mcp_enabled ? "" : (
    local.mcp_adopted ? local.existing_mcp_client_id : "mcp-${random_id.mcp_client_id_suffix[0].hex}"
  )
  mcp_client_secret = !var.mcp_enabled ? "" : (
    local.existing_mcp_client_secret != "" ? local.existing_mcp_client_secret : random_password.mcp_client_secret[0].result
  )

  service_clients = concat(
    var.registry_enabled ? [{
      serviceId         = "registry"
      kind              = "service"
      canListPrincipals = true
      credential = base64encode(jsonencode({
        clientId = local.registry_client_id
        keyId    = local.registry_key_id
        key      = local.registry_public_key_pem
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
  count       = var.registry_enabled && !local.registry_adopted ? 1 : 0
  byte_length = 4
}
resource "random_id" "registry_key_id_suffix" {
  count       = var.registry_enabled && !local.registry_adopted ? 1 : 0
  byte_length = 4
}
resource "tls_private_key" "registry" {
  count = var.registry_enabled && !local.registry_adopted ? 1 : 0
  # Must be ECDSA P-384 — identity rejects any non-P-384 client key.
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
resource "kubernetes_secret_v1" "registry" {
  count = var.registry_enabled ? 1 : 0
  lifecycle {
    precondition {
      condition     = local.registry_blob_valid
      error_message = "an existing registry credential was found but is not a base64 JSON blob with clientId, keyId and a PEM private key; fix or remove it rather than letting the provisioner mint a replacement."
    }
  }
  metadata {
    name      = var.registry_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = {
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_CREDENTIALS = base64encode(jsonencode({
      clientId = local.registry_client_id
      keyId    = local.registry_key_id
      key      = local.registry_private_key_pem
    }))
    # Raw client id, for identity.bootstrap.registryClientIdSecretRef.
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_ID = local.registry_client_id
    # Legacy + DPLAT-602 names for the same "identity is on" signal — both emitted for compat.
    FILE_SERVICE_FEATURE_FLAGS__IDENTITY_ROUTER_ENABLED = "true"
    FILE_SERVICE_IDENTITY_ROUTER_URL                    = local.identity_service_url
    ISTARI_DIGITAL_IDENTITY_SERVICE_ENABLED             = "true"
    # Bare (non-JSON) client_id so identity-service can mount this secret via
    # extraEnvSecrets and allowlist the registry's real client_id on
    # POST /api/v1/agents. Comma-separated in identity-service; a single id here
    # is valid CSV of one.
    ISTARI_DIGITAL_IDENTITY_SERVICE_AGENT_PROVISIONING_CLIENT_IDS = local.registry_client_id
  }
}

# ---- frontend (kind: public / PKCE — no keypair) ----
resource "random_id" "frontend_client_id_suffix" {
  count       = var.frontend_enabled && !local.frontend_adopted ? 1 : 0
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
  count       = var.mcp_enabled && !local.mcp_adopted ? 1 : 0
  byte_length = 4
}
resource "random_password" "mcp_client_secret" {
  count   = var.mcp_enabled && nonsensitive(local.existing_mcp_client_secret == "") ? 1 : 0
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
    ISTARI_DIGITAL_IDENTITY_SERVICE_CLIENT_SECRET = local.mcp_client_secret
    ISTARI_DIGITAL_IDENTITY_SERVICE_ENABLED       = "true"
  }
}

# ---- identity's platform clients — what identity-service registers from at startup ----
# identity-service 2.0.0-pre.14 and later refuse to start without these three settings.
resource "kubernetes_secret_v1" "identity_platform_clients" {
  count = var.registry_enabled || var.frontend_enabled || var.mcp_enabled ? 1 : 0
  metadata {
    name      = var.identity_platform_clients_secret_name
    namespace = var.namespace
    labels    = var.common_labels
  }
  data = merge(
    var.registry_enabled ? {
      ISTARI_DIGITAL_IDENTITY_SERVICE_REGISTRY_PUBLIC_KEY_B64 = base64encode(local.registry_public_key_pem)
    } : {},
    var.frontend_enabled ? {
      ISTARI_DIGITAL_IDENTITY_SERVICE_FRONTEND_REDIRECT_URIS = join(",", local.frontend_all_redirect_uris)
    } : {},
    var.mcp_enabled ? {
      ISTARI_DIGITAL_IDENTITY_SERVICE_MCP_REDIRECT_URIS = join(",", local.mcp_all_redirect_uris)
    } : {},
  )
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
      error_message = "frontend is enabled but no redirect URI could be resolved and none is registered already — set provisioner.mainDomain (or provisioner.clients.frontend.redirectUri)."
    }
    precondition {
      condition     = !var.mcp_enabled || length(local.mcp_all_redirect_uris) > 0
      error_message = "mcp is enabled but no redirect URI could be resolved and none is registered already — set provisioner.mainDomain (or provisioner.clients.mcp.redirectUri)."
    }
    precondition {
      # Scoped to the clients that actually consume identity_service_url (registry, frontend) --
      # an mcp-only configuration never writes this value anywhere, so it must not be required
      # for one.
      condition     = !local.identity_service_url_required || local.identity_service_url != ""
      error_message = "registry or frontend is enabled but the identity-service URL could not be resolved and no earlier credential records one — set provisioner.mainDomain (or provisioner.identityServiceUrl)."
    }
  }
}

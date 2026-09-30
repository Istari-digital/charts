variable "namespace" {
  type = string
}

variable "common_labels" {
  type    = map(string)
  default = {}
}

# ---- per-client enable flags ----
variable "registry_enabled" {
  type = bool
}
variable "frontend_enabled" {
  type = bool
}
variable "mcp_enabled" {
  type = bool
}

# ---- Secret names this run writes into (from the shared naming helpers) ----
variable "registry_secret_name" {
  type = string
}
variable "frontend_secret_name" {
  type = string
}
variable "mcp_secret_name" {
  type = string
}
variable "identity_platform_clients_secret_name" {
  type        = string
  description = "Secret carrying the settings identity-service registers the registry, frontend and mcp clients from at startup."
}
variable "identity_service_clients_secret_name" {
  type = string
}

# ---- redirect URI / identity-service URL inputs ----
variable "main_domain" {
  type    = string
  default = ""
}
variable "identity_service_url" {
  type    = string
  default = ""
}
variable "frontend_redirect_uri" {
  type    = string
  default = ""
}
variable "frontend_extra_redirect_uris" {
  type    = list(string)
  default = []
}
variable "mcp_redirect_uri" {
  type    = string
  default = ""
}
variable "mcp_extra_redirect_uris" {
  type    = list(string)
  default = []
}
# Redirect URIs for the hosts this release serves the frontend and MCP at (Ingress or VirtualService).
variable "frontend_host_redirect_uris" {
  type    = list(string)
  default = []
}
variable "mcp_host_redirect_uris" {
  type    = list(string)
  default = []
}

# ---- reuse of credentials that already exist ----
# Each source is a Secret and a key, tried in order after this provisioner's own earlier Secret.
variable "adopt_existing" {
  type    = bool
  default = true
}
variable "adopt_registry_sources" {
  type    = list(object({ name = string, key = string }))
  default = []
}
variable "adopt_frontend_sources" {
  type    = list(object({ name = string, key = string }))
  default = []
}
variable "adopt_mcp_sources" {
  type    = list(object({ name = string, key = string }))
  default = []
}
variable "adopt_mcp_secret_sources" {
  type    = list(object({ name = string, key = string }))
  default = []
}
variable "adopt_identity_service_url_sources" {
  type    = list(object({ name = string, key = string }))
  default = []
}
# identity-service's own env Secrets: checked for platform clients it already registers.
variable "identity_env_secret_names" {
  type    = list(string)
  default = []
}
variable "adopt_redirect_uris_secret_name" {
  type    = string
  default = ""
}

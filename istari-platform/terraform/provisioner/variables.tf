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
variable "secure_connection_enabled" {
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
variable "secure_connection_secret_name" {
  type = string
}
variable "frontend_secret_name" {
  type = string
}
variable "mcp_secret_name" {
  type = string
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

variable "auto_configure_subdomains" {
  description = "Whether to automatically configure subdomains"
  type        = bool
  default     = false
}


variable "frontend_service_post_logout_redirect_uris" {
  type    = list(string)
  default = []
}

variable "frontend_service_redirect_uris" {
  type    = list(string)
  default = []
}

variable "namespace" {
  type    = string
  default = "default_namespace"
}

variable "org_name" {
  type        = string
  description = "Name of the organization"
  default     = "istari"
}

variable "org_owner_email" {
  type        = string
  description = "Email of the organization owner"
}

variable "org_owner_firstname" {
  type        = string
  description = "First name of the organization owner"
  default     = "Istari"
}

variable "org_owner_lastname" {
  type        = string
  description = "Last name of the organization owner"
  default     = "Local"
}

variable "org_owner_username" {
  type        = string
  description = "Username of the organization owner"
  default     = "istari_local"
}

variable "org_owner_temporary_password" {
  type        = string
  description = "Temporary password for the organization owner"
  default     = "IstariLocalPassword1!"
}

variable "mcp_enabled" {
  description = "Whether the MCP Service will be installed in the environment"
  type        = bool
  default     = false
}

variable "main_domain" {
  type        = string
  description = "Main domain for the organization"
}

variable "mcp_post_logout_redirect_uris" {
  description = "Post-logout redirect URIs for the Zitadel application 'mcp-service'"
  type        = list(string)
  default     = []
}

variable "mcp_redirect_uris" {
  description = "Redirect URIs for the Zitadel application 'mcp-service'"
  type        = list(string)
  default     = []
}

variable "mcp_additional_redirect_uris" {
  description = "Additional redirect URIs for the Zitadel application 'mcp-service'"
  type        = list(string)
  default     = []
}

variable "privacy_link" {
  type    = string
  default = ""
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "istari"
}

variable "sa_json_file" {
  type        = string
  description = "Path to the service account JSON file"
  default     = "/machinekey/zitadel-admin-sa.json"
}

variable "smtp_enabled" {
  type        = bool
  description = "Enable SMTP configuration"
  default     = false
}

variable "smtp_host" {
  type        = string
  description = "SMTP host"
  default     = ""
}

variable "smtp_user" {
  type        = string
  description = "SMTP user"
  default     = ""
}

variable "smtp_password" {
  type        = string
  description = "SMTP password"
  default     = ""
}

variable "smtp_tls" {
  type        = bool
  description = "Enable TLS for SMTP"
  default     = true
}

variable "smtp_sender_address" {
  type        = string
  description = "Sender address for SMTP"
  default     = ""
}

variable "smtp_sender_name" {
  type        = string
  description = "Sender name for SMTP"
  default     = ""
}

variable "tos_link" {
  type    = string
  default = ""
}

variable "zitadel_domain" {
  type = string
}

variable "zitadel_insecure" {
  type        = bool
  description = "Whether to use insecure connection to ZITADEL"
  default     = false
}

variable "zitadel_port" {
  type        = number
  description = "Port for the ZITADEL instance"
  default     = 443
}

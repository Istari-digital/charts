locals {
  frontend_service_post_logout_redirect_uris = var.auto_configure_subdomains ? [
    "https://${var.main_domain}",
    "https://v2.${var.main_domain}",
    "https://www.${var.main_domain}",
  ] : var.frontend_service_post_logout_redirect_uris

  frontend_service_redirect_uris = var.auto_configure_subdomains ? [
    "https://${var.main_domain}",
    "https://v2.${var.main_domain}",
    "https://www.${var.main_domain}",
    "https://magic-docs.${var.main_domain}",
  ] : var.frontend_service_redirect_uris

  mcp_post_logout_redirect_uris = var.auto_configure_subdomains ? [
    "https://mcp.${var.main_domain}",
  ] : var.mcp_post_logout_redirect_uris

  mcp_redirect_uris = var.auto_configure_subdomains ? concat(
    var.mcp_additional_redirect_uris,
    [
      "https://mcp.${var.main_domain}"
    ]
  ) : var.mcp_redirect_uris
}

resource "zitadel_org" "default" {
  name       = var.org_name
  is_default = true
}

resource "zitadel_project" "istari" {
  name                   = var.project_name
  org_id                 = zitadel_org.default.id
  project_role_assertion = true
  project_role_check     = false
  has_project_check      = true
}

resource "zitadel_project_role" "customer_admin" {
  project_id   = zitadel_project.istari.id
  org_id       = zitadel_org.default.id
  role_key     = "customer_admin"
  display_name = "customer_admin"
  group        = "customer_admin"
}

resource "zitadel_project_role" "istari_agent" {
  project_id   = zitadel_project.istari.id
  org_id       = zitadel_org.default.id
  role_key     = "istari_agent"
  display_name = "istari_agent"
  group        = "istari_agent"
}

resource "zitadel_project_role" "service_admin" {
  project_id   = zitadel_project.istari.id
  org_id       = zitadel_org.default.id
  role_key     = "service_admin"
  display_name = "service_admin"
  group        = "service_admin"
}

resource "zitadel_project_grant" "default" {
  project_id     = zitadel_project.istari.id
  org_id         = zitadel_org.default.id
  granted_org_id = zitadel_org.default.id
  role_keys      = ["customer_admin", "istari_agent", "service_admin"]
  depends_on     = [zitadel_project_role.customer_admin, zitadel_project_role.istari_agent, zitadel_project_role.service_admin]
}

resource "zitadel_application_oidc" "istari_frontend_service" {
  project_id                  = zitadel_project.istari.id
  org_id                      = zitadel_org.default.id
  name                        = "frontend-service"
  redirect_uris               = local.frontend_service_redirect_uris
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
  post_logout_redirect_uris   = local.frontend_service_post_logout_redirect_uris
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_NONE"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = true
  access_token_type           = "OIDC_TOKEN_TYPE_JWT"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = true
  additional_origins          = []
}

resource "zitadel_application_oidc" "mcp_service_post" {
  count                       = var.mcp_enabled ? 1 : 0
  project_id                  = zitadel_project.istari.id
  org_id                      = zitadel_org.default.id
  name                        = "mcp-service"
  redirect_uris               = local.mcp_redirect_uris
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
  post_logout_redirect_uris   = local.mcp_post_logout_redirect_uris
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_POST"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = true
  access_token_type           = "OIDC_TOKEN_TYPE_JWT"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = true
  additional_origins          = []
}

resource "zitadel_human_user" "default" {
  org_id             = zitadel_org.default.id
  user_name          = var.org_owner_username
  first_name         = var.org_owner_firstname
  last_name          = var.org_owner_lastname
  nick_name          = "${var.org_owner_firstname} ${var.org_owner_lastname}"
  display_name       = "${var.org_owner_firstname} ${var.org_owner_lastname}"
  preferred_language = "en"
  email              = var.org_owner_email
  is_email_verified  = true
  initial_password   = var.org_owner_temporary_password
}

resource "zitadel_instance_member" "default" {
  user_id = zitadel_human_user.default.id
  roles   = ["IAM_OWNER"]
}

resource "zitadel_application_api" "registry-service" {
  project_id       = zitadel_project.istari.id
  org_id           = zitadel_org.default.id
  name             = "registry-service"
  auth_method_type = "API_AUTH_METHOD_TYPE_PRIVATE_KEY_JWT"
}

resource "zitadel_application_key" "registry-service-key" {
  depends_on      = [zitadel_application_api.registry-service]
  org_id          = zitadel_org.default.id
  project_id      = zitadel_project.istari.id
  app_id          = zitadel_application_api.registry-service.id
  key_type        = "KEY_TYPE_JSON"
  expiration_date = "2519-04-01T08:45:00Z"
}

resource "zitadel_machine_user" "registry-service-user" {
  depends_on        = [zitadel_application_key.registry-service-key]
  org_id            = zitadel_org.default.id
  user_name         = "RegistryServiceMachineUser"
  name              = "RegistryServiceMachineUser"
  description       = "The machine user for the registry service"
  access_token_type = "ACCESS_TOKEN_TYPE_JWT"
}

resource "zitadel_machine_key" "registry-service-machine-key" {
  depends_on      = [zitadel_machine_user.registry-service-user]
  org_id          = zitadel_org.default.id
  user_id         = zitadel_machine_user.registry-service-user.id
  key_type        = "KEY_TYPE_JSON"
  expiration_date = "2519-04-01T08:45:00Z"
}

resource "zitadel_personal_access_token" "registry-service-management-token" {
  depends_on      = [zitadel_machine_key.registry-service-machine-key]
  org_id          = zitadel_org.default.id
  user_id         = zitadel_machine_user.registry-service-user.id
  expiration_date = "2519-04-01T08:45:00Z"
}

resource "zitadel_org_member" "registry-service-default" {
  org_id  = zitadel_org.default.id
  user_id = zitadel_machine_user.registry-service-user.id
  roles   = ["ORG_OWNER"]
}

resource "zitadel_org_member" "human-default" {
  org_id  = zitadel_org.default.id
  user_id = zitadel_human_user.default.id
  roles   = ["ORG_OWNER"]
}

resource "zitadel_user_grant" "default" {
  project_id       = zitadel_project.istari.id
  org_id           = zitadel_org.default.id
  role_keys        = ["customer_admin", "istari_agent", "service_admin"]
  user_id          = zitadel_human_user.default.id
  project_grant_id = zitadel_project_grant.default.id
  depends_on       = [zitadel_human_user.default, zitadel_project.istari, zitadel_org.default]
}

resource "zitadel_default_login_policy" "default" {
  default_redirect_uri          = "https://${var.main_domain}"
  user_login                    = true
  allow_register                = false
  allow_external_idp            = true
  force_mfa                     = false
  force_mfa_local_only          = false
  passwordless_type             = "PASSWORDLESS_TYPE_ALLOWED"
  hide_password_reset           = "false"
  ignore_unknown_usernames      = false
  password_check_lifetime       = "240h0m0s"
  external_login_check_lifetime = "240h0m0s"
  mfa_init_skip_lifetime        = "720h0m0s"
  second_factor_check_lifetime  = "18h0m0s"
  multi_factor_check_lifetime   = "12h0m0s"
  allow_domain_discovery        = true
  disable_login_with_email      = false
  disable_login_with_phone      = false
}

resource "zitadel_default_privacy_policy" "default" {
  tos_link     = var.tos_link
  privacy_link = var.privacy_link
}

resource "zitadel_smtp_config" "default" {
  count            = var.smtp_enabled ? 1 : 0
  sender_address   = var.smtp_sender_address
  sender_name      = var.smtp_sender_name
  tls              = var.smtp_tls
  host             = var.smtp_host
  user             = var.smtp_user
  password         = var.smtp_password
  reply_to_address = var.smtp_sender_address
  set_active       = true
}

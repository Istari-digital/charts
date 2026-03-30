output "secret_file" {
  value = templatefile("${path.module}/secrets.yaml.tftpl", {
    common_domain                  = var.zitadel_insecure ? "http://${var.zitadel_domain}:${var.zitadel_port}" : "https://${var.zitadel_domain}"
    rs_zitadel_client_id           = zitadel_application_api.registry-service.client_id
    rs_zitadel_project_id          = zitadel_project.istari.id
    rs_zitadel_project_grant_id    = zitadel_project_grant.default.id
    rs_zitadel_secret              = base64encode(zitadel_application_key.registry-service-key.key_details)
    rs_zitadel_user_manager_secret = base64encode(zitadel_machine_key.registry-service-machine-key.key_details)
    fe_zitadel_client_id           = zitadel_application_oidc.istari_frontend_service.client_id
    mcp_zitadel_client_id          = var.mcp_enabled ? zitadel_application_oidc.mcp_service_post[0].client_id : ""
    mcp_zitadel_secret             = var.mcp_enabled ? zitadel_application_oidc.mcp_service_post[0].client_secret : ""
  })
  sensitive = true
}

# istari-zitadel-configurator

![Version: 1.6.1](https://img.shields.io/badge/Version-1.6.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 8.7.2](https://img.shields.io/badge/AppVersion-8.7.2-informational?style=flat-square)

A Helm chart for configuring Zitadel instance to work with Istari.

## Overview
This chart automates the setup and configuration of Zitadel resources for the Istari Platform.

## Features
- Automates ZITADEL configuration for Istari environments
- Integrates with Istari platform services
- Supports custom values for flexible deployments

## Prerequisites
- [Helm 3.x](https://helm.sh/)
- Access to a Kubernetes cluster

## Installation

>[!NOTE]
>Istari needs to grant access to the Istari Artifactory to allow customers to pull the istari-zitadel-configurator helm chart.
>Please contact [Support Team](mailto:support@istaridigital.com) for more information.

Instructions for installing the istari-zitadel-configurator chart are available in the IT Admins section of the [official Istari Documentation](https://docs.istaridigital.com/).

## Configuration
You must customize the deployment by providing your own `values.yaml` file. See the [values.yaml](values.yaml) for all available configuration options.

Example:
```yaml
configurator:
  org_name: "istari"
  zitadel_domain: "your-zitadel-domain"
  # ... more configuration ...
```

## Uninstall
```sh
helm uninstall istari-zitadel-configurator
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment. For more information, see: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| configurator.auto_configure_subdomains | bool | `true` | Enable auto configuration of subdomains. If enabled is set to true. If set to true, the following domains will be assumed (Please note using domain.com as an example): Frontend service subdomain: https://domain.com and https://v2.domain.com MCP service subdomain: https://mcp.domain.com Any additional subdomains required by Istari-Platform helm chart will take values as:   http://[subdomain].domain.com  If set to false, the following values have to be provided: `frontend_post_logout_redirect_uris`, `frontend_redirect_uris`, `mcp_service.post_logout_redirect_uris`, `mcp_service.redirect_uris` |
| configurator.frontend_service_post_logout_redirect_uris | list | `["https://domain.com"]` | URLs inside this array should not end with a trailing "/" |
| configurator.frontend_service_redirect_uris | list | `["https://domain.com"]` | URLs inside this array should not end with a trailing "/" |
| configurator.main_domain | string | `"domain.com"` | This will determine the main domain for the Terraform configuration. |
| configurator.mcp_service | object | `{"additional_redirect_uris":[],"enabled":false,"post_logout_redirect_uris":["https://mcp.domain.com"],"redirect_uris":["https://mcp.domain.com"]}` | MCP service |
| configurator.mcp_service.additional_redirect_uris | list | `[]` | In case auto_configure_subdomains is enabled, this might be used to configure additional domains for the application in Ziatdel. |
| configurator.mcp_service.enabled | bool | `false` | Whether to create MCP application in Zitadel |
| configurator.mcp_service.post_logout_redirect_uris | list | `["https://mcp.domain.com"]` | URLs inside this array should not end with a trailing "/". Required only if MCP is enabled. |
| configurator.mcp_service.redirect_uris | list | `["https://mcp.domain.com"]` | URLs inside this array should not end with a trailing "/". Required only if MCP is enabled. |
| configurator.org_name | string | `"istari"` | Display name of the organization |
| configurator.org_owner | object | `{"email":"local_admin@domain.com","firstname":"local","lastname":"admin","temporary_password":"IstariLocalPassword1!","username":"local_admin"}` | Organization owner user |
| configurator.plan_only | bool | `false` | Set to true to enable debug mode for the Terraform plan; pod logs will display the planning output. Set to false to apply the Terraform changes instead. |
| configurator.privacy_link | string | `"https://domain.com/privacy-policy"` | Privacy policy link |
| configurator.project_name | string | `"istari"` | Display name of the project |
| configurator.smtp.enabled | bool | `false` | Whether to create SMTP application in Zitadel |
| configurator.smtp.existing_secret | bool | `true` | Recommended way to configure SMTP settings. Indicates whether to use an existing secret or create a new one. |
| configurator.smtp.existing_secret_key | string | `"smtp_password"` | The key in the existing secret that contains the SMTP password. |
| configurator.smtp.existing_secret_name | string | `"configurator-secrets"` | The name of the existing secret that contains the SMTP settings. |
| configurator.smtp.host | string | `""` | SMTP Host |
| configurator.smtp.password | string | `""` | Not recommended. if smtp_existing_secret is true, this will be ignored |
| configurator.smtp.port | int | `587` | SMTP Port |
| configurator.smtp.sender_address | string | `""` | Email address to use for sending out emails |
| configurator.smtp.sender_name | string | `""` | Name to use for sending out emails |
| configurator.smtp.tls | bool | `true` | Whether to use TLS for SMTP communication |
| configurator.smtp.username | string | `""` | Username to use for SMTP authentication |
| configurator.tos_link | string | `"https://domain.com/terms-of-service"` | Terms of service link |
| configurator.zitadel_domain | string | `"zitadel.domain.com"` | Ziatdel domain |
| configurator.zitadel_insecure | bool | `false` | Whether to connect to Ziatdel over insecure channel |
| configurator.zitadel_port | int | `443` | Ziatdel port |
| configurator.zitadel_sa_secret_name | string | `"zitadel-sa-user"` | The secret name the is created by Ziatdel helm chart |
| extraEnv | list | `[]` | Additional environment variables to add to the container. |
| extraVolumeMounts | list | `[]` | Additional volume mounts to add to the container. |
| extraVolumes | list | `[]` | Additional volumes to add to the pod. |
| fullnameOverride | string | `"istari-zitadel-configurator"` | Override the name of the chart. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy (e.g., Always, IfNotPresent, Never) |
| image.registry | string | `"istaridigital.jfrog.io"` | Docker registry where the image is hosted |
| image.repository | string | `"main-docker-local/zitadel-configurator"` | Docker repository for the image |
| image.tag | string | `"1.0.0"` | Image tag to use |
| imagePullSecrets[0].name | string | `"docker-pull-secret"` |  |
| nameOverride | string | `"istari-zitadel-configurator"` | Override the name of the chart. |
| nodeSelector | object | `{}` | Node selector for pod assignment. For more information, see: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| override.enabled | bool | `false` | Enable overriding terraform plan with custom pre-existing plan. If enabled is set to true, "configurator" part of the values.yaml will be ignored. |
| override.entrypoint_secret_name | string | `"istari-zitadel-configurator-overrides-entrypoint"` | Name of kubernetes secret containing entrypoint script for the container |
| override.plan_secret_name | string | `"istari-zitadel-configurator-overrides-terraform"` | Name of kubernetes secret containing terraform plan |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{"fsGroup":2000}` | Security context for the Pod. For more information, see: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| podSecurityContext.fsGroup | int | `2000` | Group ID for all files created by containers in the Pod |
| resources | object | `{"limits":{"cpu":"1","memory":"512Mi"},"requests":{"cpu":"1","memory":"512Mi"}}` | Resource requests and limits for the container. For more information, see: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":1000}` | Security context for the container. For more information, see: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| securityContext.allowPrivilegeEscalation | bool | `false` | Prevent privilege escalation |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop all Linux capabilities for the container |
| securityContext.readOnlyRootFilesystem | bool | `true` | Mount the root filesystem as read-only |
| securityContext.runAsNonRoot | bool | `true` | Run the container as a non-root user |
| securityContext.runAsUser | int | `1000` | User ID to run the entrypoint of the container process |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` | Tolerations for pod assignment. For more information, see: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| trustedCertBundleUseExistingConfigMap | string | `""` | Name of an existing ConfigMap containing trusted CA certificates (key: bundle.crt). Used in SSL inspection environments (Zscaler, Broadcom, Fortinet). When set to a non-empty string, the ConfigMap is mounted into the container at /etc/pki/tls/certs/ca-bundle.crt. Leave empty to disable. |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Istari Digital Infrastructure Team | <infra@istaridigital.com> |  |

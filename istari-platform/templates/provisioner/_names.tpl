{{/*
Default name/prefix for provisioner resources (ServiceAccount/Role/RoleBinding/Job/terraform-files
Secret -- all release-scoped, unlike the output-credential Secrets below).
*/}}
{{- define "provisioner.fullname" -}}
    {{- /* trunc 33, not 63: bounded so the longest suffix appended below (-terraform-files, 16
           chars) never gets truncated away -- 63-16=47 would technically be tight enough, but 33
           matches the same conservative bound reserved for the (now-static) output Secret names
           this helper used to feed, kept here rather than re-tuned per suffix. */ -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
Secret carrying the packaged .tf files + rendered terraform.tfvars.
*/}}
{{- define "provisioner.terraformFilesSecretName" -}}
{{ printf "%s-terraform-files" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The one-shot provisioning Job name.
*/}}
{{- define "provisioner.jobName" -}}
{{ printf "%s-apply" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Output-credential Secret names below are deliberately STATIC literals, not derived from
.fullname/.Release.Name -- provisioner is meant to be a namespace-singleton (like
istari-zitadel-configurator's own static "zitadel-*-env" Secret names), and a consuming release
(one-release-per-service topology) computes these same helpers from ITS OWN .Release.Name. A
release-relative name would make the producer and consumer releases derive different Secret
names for the same credential, which is exactly the bug this fixes.
*/}}

{{/*
Secret carrying registry's private credential blob. Listed in fileservice.extraEnvSecrets.
*/}}
{{- define "provisioner.registrySecretName" -}}
istari-provisioner-registry-credentials
{{- end }}

{{/*
Secret carrying secure-connection-service's private credential blob (kind:service, DPLAT-924).
*/}}
{{- define "provisioner.secureConnectionSecretName" -}}
istari-provisioner-secure-connection-credentials
{{- end }}

{{/*
Secret carrying frontend's client_id.
*/}}
{{- define "provisioner.frontendSecretName" -}}
istari-provisioner-frontend-credentials
{{- end }}

{{/*
Secret carrying mcp's client_id + placeholder client_secret.
*/}}
{{- define "provisioner.mcpSecretName" -}}
istari-provisioner-mcp-credentials
{{- end }}

{{/*
Secret carrying serviceClients.yaml — what identity's provision-service-clients Job mounts.
*/}}
{{- define "provisioner.serviceClientsSecretName" -}}
istari-provisioner-service-clients
{{- end }}

{{/*
Secret carrying the settings identity-service registers the registry, frontend and mcp clients
from at startup. Listed in identity's extraEnvSecrets.
*/}}
{{- define "provisioner.identityPlatformClientsSecretName" -}}
istari-provisioner-identity-platform-clients
{{- end }}

{{/*
Whether identity-service's platform-clients Secret is written: the registry, frontend or mcp
client is enabled. Returns "true" or "".
*/}}
{{- define "provisioner.identityPlatformClientsEnabled" -}}
{{- if or (include "provisioner.clientEnabled" (list . "registry")) (include "provisioner.clientEnabled" (list . "frontend")) (include "provisioner.clientEnabled" (list . "mcp")) -}}
true
{{- end -}}
{{- end }}

{{/*
Whether at least one client is enabled. Returns "true" or "".
*/}}
{{- define "provisioner.anyClientEnabled" -}}
{{- if or (include "provisioner.clientEnabled" (list . "registry")) (include "provisioner.clientEnabled" (list . "secureConnection")) (include "provisioner.clientEnabled" (list . "frontend")) (include "provisioner.clientEnabled" (list . "mcp")) -}}
true
{{- end -}}
{{- end }}

{{/*
Whether this release runs the provisioner: as written, or, unset, where it deploys identity-service.
*/}}
{{- define "provisioner.enabled" -}}
{{- $v := dig "enabled" nil .Values.provisioner -}}
{{- if kindIs "bool" $v -}}
{{- if $v }}true{{ end -}}
{{- else if include "istari-platform.identityEnabled" . -}}
true
{{- end -}}
{{- end }}

{{/*
One client's enabled value as written, or, unset, whether clients use identity-service; call with (list $ "<client>").
*/}}
{{- define "provisioner.clientEnabled" -}}
{{- $root := index . 0 -}}
{{- $v := dig (index . 1) "enabled" nil (default dict $root.Values.provisioner.clients) -}}
{{- if kindIs "bool" $v -}}
{{- if $v }}true{{ end -}}
{{- else if eq (include "istari-platform.identityClientIntegration" $root) "true" -}}
true
{{- end -}}
{{- end }}

{{/*
Whether the bootstrap roles Job has a registry client id: set directly, in another Secret, or written by this provisioner.
*/}}
{{- define "identity.bootstrap.registryClientIdResolves" -}}
{{- $b := .Values.identity.bootstrap -}}
{{- $ref := default dict $b.registryClientIdSecretRef -}}
{{- if $b.registryClientId -}}
true
{{- else if and $ref.name (ne $ref.name (include "provisioner.registrySecretName" .)) -}}
true
{{- else if and $ref.name (include "provisioner.clientEnabled" (list . "registry")) -}}
true
{{- end -}}
{{- end }}

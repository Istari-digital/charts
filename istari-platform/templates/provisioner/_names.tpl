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
Whether at least one client is enabled. Returns "true" or "".
*/}}
{{- define "provisioner.anyClientEnabled" -}}
{{- $c := .Values.provisioner.clients -}}
{{- if or $c.registry.enabled $c.secureConnection.enabled $c.frontend.enabled $c.mcp.enabled -}}
true
{{- end -}}
{{- end }}

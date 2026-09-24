{{/*
Default name/prefix for provisioner resources.
*/}}
{{- define "provisioner.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "provisioner" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "provisioner" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
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
Secret carrying registry's private credential blob. Listed in fileservice.extraEnvSecrets.
*/}}
{{- define "provisioner.registrySecretName" -}}
{{ printf "%s-registry-credentials" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret carrying secure-connection-service's private credential blob (kind:service, DPLAT-924).
*/}}
{{- define "provisioner.secureConnectionSecretName" -}}
{{ printf "%s-secure-connection-credentials" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret carrying frontend's client_id.
*/}}
{{- define "provisioner.frontendSecretName" -}}
{{ printf "%s-frontend-credentials" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret carrying mcp's client_id + placeholder client_secret.
*/}}
{{- define "provisioner.mcpSecretName" -}}
{{ printf "%s-mcp-credentials" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret carrying serviceClients.yaml — what identity's provision-service-clients Job mounts.
*/}}
{{- define "provisioner.serviceClientsSecretName" -}}
{{ printf "%s-service-clients" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
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

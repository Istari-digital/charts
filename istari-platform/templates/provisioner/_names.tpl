{{/*
Name/prefix for provisioner resources (ServiceAccount/Role/RoleBinding/Job) -- release-scoped,
unlike the static output-credential Secret names below.
*/}}
{{- define "provisioner.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
The one-shot provisioning Job name.
*/}}
{{- define "provisioner.jobName" -}}
{{ printf "%s-apply" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Static literals, not .Release.Name-derived: producer and consumer releases must agree on these
names regardless of which release renders which.
*/}}

{{/*
Secret carrying registry's private credential blob.
*/}}
{{- define "provisioner.registrySecretName" -}}
istari-provisioner-registry-credentials
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
Secret carrying the env vars identity-service reads at startup to self-register
registry/frontend/mcp.
*/}}
{{- define "provisioner.identityPlatformClientsSecretName" -}}
istari-provisioner-identity-platform-clients
{{- end }}

{{/*
Whether at least one client is enabled. Returns "true" or "".
*/}}
{{- define "provisioner.anyClientEnabled" -}}
{{- $c := .Values.provisioner.clients -}}
{{- if or $c.registry.enabled $c.frontend.enabled $c.mcp.enabled -}}
true
{{- end -}}
{{- end }}

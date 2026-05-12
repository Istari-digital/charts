{{/*
Default name/prefix for identity-service resources
*/}}
{{- define "identity-service.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "identity-service" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "identity-service" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
identity-service default env var configmap name
*/}}
{{- define "identity-service.configmap.name" -}}
{{ printf "%s-envvars" (include "identity-service.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

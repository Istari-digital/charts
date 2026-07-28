{{/*
Default name/prefix for frontend resources
*/}}
{{- define "frontend.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "frontend" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "frontend" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
frontend default env var configmap name
*/}}
{{- define "frontend.configmap.name" -}}
{{ printf "%s-envvars" (include "frontend.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

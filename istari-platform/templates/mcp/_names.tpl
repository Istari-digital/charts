{{/*
Default name/prefix for mcp resources
*/}}
{{- define "mcp.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "mcp" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "mcp" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
mcp default env var configmap name
*/}}
{{- define "mcp.configmap.name" -}}
{{ printf "%s-envvars" (include "mcp.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

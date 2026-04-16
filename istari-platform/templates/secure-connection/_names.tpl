{{/*
Default name/prefix for secure-connection resources
*/}}
{{- define "secure-connection.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "secure-connection" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "secure-connection" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
secure-connection default env var configmap name
*/}}
{{- define "secure-connection.configmap.name" -}}
{{ printf "%s-envvars" (include "secure-connection.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

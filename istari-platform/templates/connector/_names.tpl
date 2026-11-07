{{/*
Default name/prefix for connector resources
*/}}
{{- define "connector.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "connector" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "connector" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
connector default env var configmap name
*/}}
{{- define "connector.configmap.name" -}}
{{ printf "%s-envvars" (include "connector.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Default name/prefix for identity resources
*/}}
{{- define "identity.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "identity" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "identity" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
identity default env var configmap name
*/}}
{{- define "identity.configmap.name" -}}
{{ printf "%s-envvars" (include "identity.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

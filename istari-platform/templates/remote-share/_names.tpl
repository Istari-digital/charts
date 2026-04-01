{{/*
Default name/prefix for remote-share resources
*/}}
{{- define "remote-share.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "remote-share" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "remote-share" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
remote-share default env var configmap name
*/}}
{{- define "remote-share.configmap.name" -}}
{{ printf "%s-envvars" (include "remote-share.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Default name/prefix for router resources
*/}}
{{- define "router.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "router" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "router" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
router Caddyfile configmap name
*/}}
{{- define "router.configmap.name" -}}
{{ printf "%s-caddyfile" (include "router.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

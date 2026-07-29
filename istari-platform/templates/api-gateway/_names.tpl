{{/*
Default name/prefix for api-gateway resources
*/}}
{{- define "api-gateway.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "api-gateway" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "api-gateway" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
api-gateway proxy-config configmap name. Deliberately proxy-agnostic (not "-caddyfile"):
swapping the proxy implementation must not rename chart resources.
*/}}
{{- define "api-gateway.configmap.name" -}}
{{ printf "%s-config" (include "api-gateway.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Default name/prefix for fileservice resources
*/}}
{{- define "fileservice.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "fileservice" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "fileservice" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
Name of the fileservice defaults configmap (currently OTEL env only; rendered when both fileservice.enabled and jaeger.enabled are true)
*/}}
{{- define "fileservice.configmap.name" -}}
{{ printf "%s-envvars" (include "fileservice.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Default name/prefix for magic-docs resources
*/}}
{{- define "magic-docs.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "magic-docs" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "magic-docs" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

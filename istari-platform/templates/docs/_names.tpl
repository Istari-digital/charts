{{/*
Default name/prefix for docs resources
*/}}
{{- define "docs.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "docs" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "docs" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

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

{{/*
Default name/prefix for shared resources
*/}}
{{- define "shared.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "shared" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "shared" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
Name of the shared trusted certs configmap
*/}}
{{- define "shared.trustedCerts.name" -}}
{{ printf "%s-trusted-certs" (include "shared.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

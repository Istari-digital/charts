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

{{/*
One-shot Job that registers the registry-service identity-router client in the ClientStore.
*/}}
{{- define "identity.routerClientRegistration.jobName" -}}
{{- printf "%s-register-router-client" (include "identity.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
True when the identity-router client registration hook Job should be rendered.
*/}}
{{- define "identity.routerClientRegistration.scheduled" -}}
{{- if and .Values.identityService.enabled .Values.fileservice.enabled }}scheduled{{- end }}
{{- end }}

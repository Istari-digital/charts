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
One-shot Job that provisions an agent's tenant and registers its public key.
Call with a dict: {"root": $, "name": <agent name>}.
*/}}
{{- define "identity.agentRegistration.jobName" -}}
{{- /* Bound the prefix and the agent-name suffix separately so a long release
       name can't truncate the suffix away and collide two agents' Job names.
       30 + len("-register-agent-")=16 + 16 = 62 <= 63 (the k8s name limit). */ -}}
{{- $prefix := include "identity.fullname" .root | trunc 30 | trimSuffix "-" -}}
{{- $agentName := .name | trunc 16 | trimSuffix "-" -}}
{{- printf "%s-register-agent-%s" $prefix $agentName | trimSuffix "-" -}}
{{- end }}

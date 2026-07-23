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
One-shot Job that registers a public (PKCE) client in the ClientStore.
Call with a dict: {"root": $, "name": <client name>}.
*/}}
{{- define "identity.publicClientRegistration.jobName" -}}
{{- printf "%s-register-client-%s" (include "identity.fullname" .root) (.name | lower | replace "_" "-") | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
One-shot Job that provisions an agent's tenant and registers its public key.
Call with a dict: {"root": $, "name": <agent name>}.
*/}}
{{- define "identity.agentRegistration.jobName" -}}
{{- /* Build a DNS-1123-safe, collision-free Job name within the 63-char limit:
       - bound the fullname prefix (24) so a long release name can't crowd out
         the rest;
       - a readable, sanitized slice of the agent name (underscores → hyphens,
         lowercased, 12) purely for human legibility;
       - an 8-char hash of the FULL agent name for uniqueness, so two agents whose
         names share a prefix (or differ only past the 12-char slice) never collide.
       24 + len("-register-agent-")=16 + 12 + 1 + 8 = 61 <= 63. */ -}}
{{- $prefix := include "identity.fullname" .root | trunc 24 | trimSuffix "-" -}}
{{- $slug := .name | lower | replace "_" "-" | trunc 12 | trimSuffix "-" -}}
{{- $hash := .name | sha256sum | trunc 8 -}}
{{- printf "%s-register-agent-%s-%s" $prefix $slug $hash | trimSuffix "-" -}}
{{- end }}

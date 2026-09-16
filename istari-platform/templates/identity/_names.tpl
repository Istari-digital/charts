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
One-shot Job that registers the registry-service client in the ClientStore.
*/}}
{{- define "identity.registryClientRegistration.jobName" -}}
{{- printf "%s-register-registry-client" (include "identity.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
One-shot Job that registers a public (PKCE) client in the ClientStore.
Call with a dict: {"root": $, "name": <client name>}.
*/}}
{{- define "identity.publicClientRegistration.jobName" -}}
{{- /* Build a DNS-1123-safe, collision-free Job name within the 63-char limit,
       mirroring identity.agentRegistration.jobName: a bounded fullname prefix,
       a readable sanitized slice of the client name, and an 8-char hash of the
       FULL name so two clients sharing a 12-char prefix never collide even if
       a long release name would otherwise truncate the distinguishing suffix.
       24 + len("-register-client-")=17 + 12 + 1 + 8 = 62 <= 63. */ -}}
{{- $prefix := include "identity.fullname" .root | trunc 24 | trimSuffix "-" -}}
{{- $slug := .name | lower | replace "_" "-" | trunc 12 | trimSuffix "-" -}}
{{- $hash := .name | sha256sum | trunc 8 -}}
{{- printf "%s-register-client-%s-%s" $prefix $slug $hash | trimSuffix "-" -}}
{{- end }}

{{/*
One-shot Job that batch-registers service and agent clients (their public keys)
in the Identity Service store from a mounted ConfigMap of public blobs.
*/}}
{{- define "identity.serviceClientProvisioning.jobName" -}}
{{- /* Bound the fullname prefix so the "-provision-service-clients" suffix (26 chars) is always
       retained — truncating AFTER appending could drop it and collide with the bare fullname. */ -}}
{{- printf "%s-provision-service-clients" (include "identity.fullname" . | trunc 37 | trimSuffix "-") | trimSuffix "-" -}}
{{- end }}

{{/*
ConfigMap holding the serviceClients list (public blobs only) the
provision-service-clients Job reads.
*/}}
{{- define "identity.serviceClientProvisioning.configMapName" -}}
{{- /* Bound the fullname prefix so the "-service-clients" suffix (16 chars) is always retained
       and never collides with identity.configmap.name ("<fullname>-envvars"). */ -}}
{{- printf "%s-service-clients" (include "identity.fullname" . | trunc 47 | trimSuffix "-") | trimSuffix "-" -}}
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

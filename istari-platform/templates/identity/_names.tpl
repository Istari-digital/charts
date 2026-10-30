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

{{/*
Names for the bootstrap hook and its password Secret. A fullname too long for the
63-character limit with its suffix is cut and given a hash of the whole name.
*/}}
{{- define "identity.localAdmin.hookName" -}}
{{- $full := include "identity.fullname" .root -}}
{{- if le (add (len $full) (len .suffix)) 63 -}}
{{- printf "%s%s" $full .suffix -}}
{{- else -}}
{{- printf "%s-%s%s" ($full | trunc (int (sub 54 (len .suffix))) | trimSuffix "-") ($full | sha256sum | trunc 8) .suffix -}}
{{- end -}}
{{- end }}

{{- define "identity.localAdmin.name" -}}
{{ include "identity.localAdmin.hookName" (dict "root" . "suffix" "-local-admin-bootstrap") }}
{{- end }}

{{- define "identity.localAdmin.passwordSecretName" -}}
{{ include "identity.localAdmin.hookName" (dict "root" . "suffix" "-local-admin-password") }}
{{- end }}

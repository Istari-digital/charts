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
{{- /* Bounded fullname prefix + an 8-char hash of the FULL fullname, so two long
       release names that share the truncated prefix still get distinct Job names
       (before-hook-creation would otherwise let one release delete/replace the
       other's Job). Mirrors identity.agentRegistration.jobName. 27 + 27 + 8 <= 63. */ -}}
{{- $full := include "identity.fullname" . -}}
{{- printf "%s-provision-service-clients-%s" ($full | trunc 27 | trimSuffix "-") ($full | sha256sum | trunc 8) -}}
{{- end }}

{{/*
ConfigMap holding the serviceClients list (public blobs only) the
provision-service-clients Job reads.
*/}}
{{- define "identity.serviceClientProvisioning.configMapName" -}}
{{- /* Same collision-safe scheme as the Job name (bounded prefix + hash of the full
       fullname); also never collides with identity.configmap.name ("<fullname>-envvars").
       37 + 17 + 8 <= 63. */ -}}
{{- $full := include "identity.fullname" . -}}
{{- printf "%s-service-clients-%s" ($full | trunc 37 | trimSuffix "-") ($full | sha256sum | trunc 8) -}}
{{- end }}

{{/*
Effective Secret name for provision-service-clients' public-blob source: explicit
identity.serviceClientProvisioning.secretName always wins; otherwise auto-derives to the
provisioner's own output Secret whenever at least one provisioner.clients.* is enabled
(deliberately NOT also gated on provisioner.enabled -- see service-client-provisioning-job.yaml
for why). Returns "" when neither applies, meaning the ConfigMap source is effective instead.
Shared by service-client-provisioning-job.yaml (which mounts it) and
service-client-provisioning-configmap.yaml (which must NOT render when this wins).
*/}}
{{- define "identity.serviceClientProvisioning.secretName" -}}
{{- $provisioning := .Values.identity.serviceClientProvisioning -}}
{{- if $provisioning.secretName -}}
{{- $provisioning.secretName -}}
{{- else if eq (include "provisioner.anyClientEnabled" .) "true" -}}
{{- include "provisioner.serviceClientsSecretName" . -}}
{{- end -}}
{{- end }}

{{/*
Whether a Secret source and a ConfigMap source are BOTH configured for
provision-service-clients -- the Secret would silently win and the ConfigMap source (and
its ConfigMap Job would ignore) would be dropped with no warning. Tests the EFFECTIVE Secret
name (identity.serviceClientProvisioning.secretName), not just the auto-derived case -- an
explicitly-set secretName alongside configMapName/serviceClients is the exact same silent-
override risk. Returns "true" or "".
*/}}
{{- define "identity.serviceClientProvisioning.sourceConflict" -}}
{{- $provisioning := .Values.identity.serviceClientProvisioning -}}
{{- $secretName := include "identity.serviceClientProvisioning.secretName" . -}}
{{- if and $secretName (or $provisioning.configMapName $provisioning.serviceClients) -}}
true
{{- end -}}
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

{{/*
identity.oidc.* -> explicit env entries for the identity web container. Takes the
identity service values (.Values.identity). Emitted as explicit `env` (not the
ConfigMap) so each value wins over any key of the same name in `secretName`:
envFrom applies the Secret after the ConfigMap, but an explicit `env` entry beats
both. That removes the "a stale OIDC key in the Secret silently overrides the
values" foot-gun — the values are authoritative for the non-secret OIDC config.
The client secret / private key stay Secret-only (OIDC_CLIENT_SECRET /
OIDC_PRIVATE_KEY).

Reads the identity.oidc.* fields directly — values.yaml is the source of truth
for their defaults (per AGENTS.md), so the template adds no fallbacks of its own.
Each field emits only when non-empty, so an empty block adds nothing. provider
and clientAuthMethod are validated against the supported enums, and an Entra
provider against what identity-service requires of it, so a mistake fails
`helm template` rather than the running pod.
*/}}
{{- define "identity.oidcEnv" -}}
{{- $oidc := .oidc -}}
{{- $provider := $oidc.provider -}}
{{- if and $provider (not (has $provider (list "zitadel" "keycloak" "entra"))) }}{{- fail (printf "identity.oidc.provider must be \"zitadel\", \"keycloak\" or \"entra\", got %q" $provider) }}{{- end }}
{{- $authMethod := $oidc.clientAuthMethod -}}
{{- if and $authMethod (not (has $authMethod (list "private_key_jwt" "client_secret_basic" "client_secret_post"))) }}{{- fail (printf "identity.oidc.clientAuthMethod must be one of private_key_jwt, client_secret_basic, client_secret_post, got %q" $authMethod) }}{{- end }}
{{- /* identity-service refuses to start on Entra without these, so catch them here instead of
       in a crash-looping pod. private_key_jwt is identity's default, and Entra rejects its
       assertions; the default tenant id is the only way an Entra login finds its tenant; a
       tenant-independent authority (common, organizations, consumers) would map one person to
       different principals depending on where they sign in. */}}
{{- if eq $provider "entra" }}
{{- if not (has $authMethod (list "client_secret_basic" "client_secret_post")) }}{{- fail (printf "identity.oidc.provider \"entra\" requires identity.oidc.clientAuthMethod client_secret_basic or client_secret_post (with ..._OIDC_CLIENT_SECRET in the Secret), got %q" $authMethod) }}{{- end }}
{{- if not (trim $oidc.defaultTenantId) }}{{- fail "identity.oidc.provider \"entra\" requires identity.oidc.defaultTenantId, the tenant mapping key Entra logins are resolved through" }}{{- end }}
{{- with $oidc.issuer }}
{{- if not (regexMatch "^https://[^/]+/([^/]+/)*[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(/.*)?$" .) }}{{- fail (printf "identity.oidc.issuer for \"entra\" must be an https URL naming the directory (tenant) GUID, e.g. https://login.microsoftonline.com/<tenant-guid>/v2.0, got %q" .) }}{{- end }}
{{- end }}
{{- end }}
{{- with $provider }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER
  value: {{ . | quote }}
{{- end }}
{{- with $oidc.issuer }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_ISSUER
  value: {{ . | quote }}
{{- end }}
{{- with $oidc.clientId }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_CLIENT_ID
  value: {{ . | quote }}
{{- end }}
{{- with $authMethod }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_CLIENT_AUTH_METHOD
  value: {{ . | quote }}
{{- end }}
{{- with $oidc.scopes }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_SCOPES
  value: {{ . | quote }}
{{- end }}
{{- with $oidc.defaultTenantId }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_JWT_DEFAULT_TENANT_ID
  value: {{ . | quote }}
{{- end }}
{{- end }}

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
The provider always emits; validations.yaml requires it and checks it against
identity.providers. Each other field emits only when non-empty, and clientAuthMethod
is validated, so a typo fails `helm template` rather than the running pod. With
provider `local` it emits only the provider and an empty issuer, ignoring the rest.
What a provider requires of the other fields (Entra's, for one) is left to
identity-service, which checks it at startup.
*/}}
{{- define "identity.oidcEnv" -}}
{{- $oidc := .oidc -}}
{{- $provider := $oidc.provider -}}
{{- $authMethod := $oidc.clientAuthMethod -}}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_SIGN_IN_PROVIDER
  value: {{ $provider | quote }}
{{- if eq $provider "local" }}
{{- range $e := .env }}
{{- if has (toString $e.name) (list "ISTARI_DIGITAL_IDENTITY_SERVICE_SIGN_IN_PROVIDER" "ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER") }}{{- fail (printf "identity.oidc.provider is \"local\", so identity.env must not set %s: remove that entry" $e.name) }}{{- end }}
{{- end }}
{{- /* Explicit env beats envFrom: blanks an issuer left in a mounted Secret, which identity-service would warn about. */}}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_ISSUER
  value: ""
{{- else }}
{{- if and $authMethod (not (has $authMethod (list "private_key_jwt" "client_secret_basic" "client_secret_post"))) }}{{- fail (printf "identity.oidc.clientAuthMethod must be one of private_key_jwt, client_secret_basic, client_secret_post, got %q" $authMethod) }}{{- end }}
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
{{- end }}

{{/*
identity.oidc.provider's accepted values, space-separated; local means local accounts.
*/}}
{{- define "identity.providers" -}}local zitadel keycloak entra okta pingfederate lastwall google{{- end }}

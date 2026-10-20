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
(including `none`, for local accounts only) and clientAuthMethod are validated against the supported enums, so a typo fails
`helm template` rather than the running pod. What a provider requires of the
other fields (Entra's, for one) is left to identity-service, which checks it at
startup.
*/}}
{{- define "identity.oidcEnv" -}}
{{- $oidc := .oidc -}}
{{- $provider := $oidc.provider -}}
{{- $authMethod := $oidc.clientAuthMethod -}}
{{- if and $authMethod (not (has $authMethod (list "private_key_jwt" "client_secret_basic" "client_secret_post"))) }}{{- fail (printf "identity.oidc.clientAuthMethod must be one of private_key_jwt, client_secret_basic, client_secret_post, got %q" $authMethod) }}{{- end }}
{{- if and $provider (not (has $provider (list "zitadel" "keycloak" "entra" "none"))) }}{{- fail (printf "identity.oidc.provider must be \"zitadel\", \"keycloak\", \"entra\" or \"none\", got %q" $provider) }}{{- end }}
{{- if eq $provider "none" }}
{{- range $key := list "issuer" "clientId" "clientAuthMethod" "scopes" "defaultTenantId" }}
{{- if get $oidc $key }}{{- fail (printf "identity.oidc.provider is \"none\", so identity.oidc.%s must be empty: an install with no identity provider signs people in with local accounts" $key) }}{{- end }}
{{- end }}
{{- range $e := .env }}
{{- if eq (toString $e.name) "ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER" }}{{- fail "identity.oidc.provider is \"none\", so identity.env must not set ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER: remove that entry" }}{{- end }}
{{- if and (eq (toString $e.name) "ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_ISSUER") (or $e.valueFrom (toString (default "" $e.value))) }}{{- fail "identity.oidc.provider is \"none\", so identity.env must not set ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_ISSUER: an install with no identity provider has no issuer" }}{{- end }}
{{- if and (has (toString $e.name) (list "ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_CLIENT_ID" "ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_PRIVATE_KEY" "ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_CLIENT_SECRET")) (or $e.valueFrom (toString (default "" $e.value))) }}{{- fail (printf "identity.oidc.provider is \"none\", so identity.env must not set %s: identity-service refuses to start with OIDC client credentials when there is no identity provider" $e.name) }}{{- end }}
{{- end }}
{{- if not .migrations.runAsJob }}{{- fail "identity.oidc.provider is \"none\", so identity.migrations.runAsJob must be true: the hook that creates the first platform admin needs the schema the migration hook creates" }}{{- end }}
{{- $email := "" }}{{- with .bootstrap }}{{- with .localAdmin }}{{- $email = .email }}{{- end }}{{- end }}
{{- if not $email }}{{- fail "identity.oidc.provider is \"none\", so identity.bootstrap.localAdmin.email must be set: it names the first platform admin, whom the chart creates as a local account" }}{{- end }}
{{- /* Explicit env beats envFrom, so an issuer left in a mounted Secret cannot select an identity provider. */}}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER
  value: ""
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_ISSUER
  value: ""
{{- else }}
{{- with $provider }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER
  value: {{ . | quote }}
{{- end }}
{{- with $oidc.issuer }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_ISSUER
  value: {{ . | quote }}
{{- end }}
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

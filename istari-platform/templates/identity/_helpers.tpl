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
and clientAuthMethod are validated against the supported enums, so a typo fails
`helm template` rather than the running pod. Known incompatible provider/authentication-method pairs are rejected after
identity.env overrides; issuer and Secret-provided settings remain startup checks.
*/}}
{{- define "identity.oidcEnv" -}}
{{- $oidc := .oidc -}}
{{- $provider := $oidc.provider -}}
{{- if and $provider (not (has $provider (list "zitadel" "keycloak" "entra" "okta" "pingfederate" "lastwall" "google"))) }}{{- fail (printf "identity.oidc.provider must be one of zitadel, keycloak, entra, okta, pingfederate, lastwall, google, got %q" $provider) }}{{- end }}
{{- $authMethod := $oidc.clientAuthMethod -}}
{{- if and $authMethod (not (has $authMethod (list "private_key_jwt" "client_secret_basic" "client_secret_post"))) }}{{- fail (printf "identity.oidc.clientAuthMethod must be one of private_key_jwt, client_secret_basic, client_secret_post, got %q" $authMethod) }}{{- end }}
{{- /* Validate only known effective values: service env overrides oidc values, while
     Secret/valueFrom inputs must be checked by identity-service at startup. */ -}}
{{- $effective := dict "provider" $provider "auth" $authMethod -}}
{{- range $entry := .env -}}
{{- $field := "" -}}
{{- if eq $entry.name "ISTARI_DIGITAL_IDENTITY_SERVICE_IDP_PROVIDER" -}}{{- $field = "provider" -}}{{- end -}}
{{- if eq $entry.name "ISTARI_DIGITAL_IDENTITY_SERVICE_OIDC_CLIENT_AUTH_METHOD" -}}{{- $field = "auth" -}}{{- end -}}
{{- if $field -}}
{{- $value := toString (default "" $entry.value) -}}
{{- if or $entry.valueFrom (contains "$(" $value) -}}{{- $value = "" -}}{{- end -}}
{{- $_ := set $effective $field $value -}}
{{- end -}}
{{- end -}}
{{- if and $effective.provider $effective.auth -}}
{{- if and (eq $effective.provider "pingfederate") (ne $effective.auth "client_secret_basic") -}}
{{- fail "identity.oidc.clientAuthMethod must be client_secret_basic for pingfederate (including identity.env overrides)" -}}
{{- end -}}
{{- if and (has $effective.provider (list "entra" "okta" "lastwall" "google")) (not (has $effective.auth (list "client_secret_basic" "client_secret_post"))) -}}
{{- fail (printf "identity.oidc.clientAuthMethod must be client_secret_basic or client_secret_post for %s (including identity.env overrides)" $effective.provider) -}}
{{- end -}}
{{- end -}}
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

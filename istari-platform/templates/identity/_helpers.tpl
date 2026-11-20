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
is validated (except under `local`, where identity-service ignores it), so a typo fails
`helm template` rather than the running pod. The fields emit as for any provider.
What a provider requires of the other fields (Entra's, for one) is left to
identity-service, which checks it at startup.
*/}}
{{- define "identity.oidcEnv" -}}
{{- $oidc := .oidc -}}
{{- $authMethod := $oidc.clientAuthMethod -}}
{{- if and $authMethod (ne (include "identity.provider" .) "local") (not (has $authMethod (list "private_key_jwt" "client_secret_basic" "client_secret_post"))) }}{{- fail (printf "identity.oidc.clientAuthMethod must be one of private_key_jwt, client_secret_basic, client_secret_post, got %q" $authMethod) }}{{- end }}
- name: ISTARI_DIGITAL_IDENTITY_SERVICE_SIGN_IN_PROVIDER
  value: {{ $oidc.provider | quote }}
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

{{/*
The provider identity-service will run, from the identity values (.Values.identity).
identity.env is appended last, so its SIGN_IN_PROVIDER entry beats identity.oidc.provider.
shortcut: reads only a literal value, so valueFrom or $(VAR) entries fall back to
identity.oidc.provider; upgrade if such an override must drive the chart's local checks.
*/}}
{{- define "identity.provider" -}}
{{- $id := . | default dict -}}
{{- $base := "" -}}
{{- with $id.oidc }}{{ with .provider }}{{ $base = toString . }}{{ end }}{{ end -}}
{{- $r := $base -}}
{{- range $id.env }}
{{- if eq .name "ISTARI_DIGITAL_IDENTITY_SERVICE_SIGN_IN_PROVIDER" }}
{{- if and (hasKey . "value") (not (contains "$(" (toString .value))) }}{{ $r = toString .value }}{{ else }}{{ $r = $base }}{{ end }}
{{- end }}
{{- end -}}
{{ $r }}
{{- end }}

{{/*
identity.oidc.provider's accepted values, space-separated; local means local accounts.
*/}}
{{- define "identity.providers" -}}local zitadel keycloak entra okta pingfederate lastwall google{{- end }}

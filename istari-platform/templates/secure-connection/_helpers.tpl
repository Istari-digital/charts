{{/*
"true" when the Secure Connection Service authenticates as the identity-service platform client
`secure_connection`, else "false". The default lives in values.yaml; `dig` covers an upgrade with
`--reuse-values` from a release whose values predate `platformClient`.
*/}}
{{- define "secure-connection.platformClient" -}}
{{- ternary "true" "false" (eq (toString (dig "platformClient" "enabled" false .Values.secureConnection)) "true") -}}
{{- end }}

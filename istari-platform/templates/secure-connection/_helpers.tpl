{{/*
"true" when the Secure Connection Service authenticates as the identity-service platform client
`secure_connection`, else "false". The default lives in values.yaml.
*/}}
{{- define "secure-connection.platformClient" -}}
{{- ternary "true" "false" (eq (toString .Values.secureConnection.platformClient.enabled) "true") -}}
{{- end }}

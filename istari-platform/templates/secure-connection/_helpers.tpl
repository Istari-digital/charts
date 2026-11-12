{{/*
"true" when the Secure Connection Service authenticates as the identity-service platform client
`secure_connection`, else "false". Read with dig so values reused from a chart without the key
render as off.
*/}}
{{- define "secure-connection.platformClient" -}}
{{- ternary "true" "false" (dig "platformClient" "enabled" false (default dict .Values.secureConnection) | toString | eq "true") -}}
{{- end }}

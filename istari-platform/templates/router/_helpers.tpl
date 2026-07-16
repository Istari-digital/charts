{{/*
Chart-managed route table for the Service Router, shared by the proxy ConfigMap and
NOTES.txt. Emits a JSON array of {prefix, service, port} objects.

Routes are deliberately NOT configurable via values: per the service-router engspec,
adding a service behind the router is a chart change, not customer configuration.
A route renders only while its backing service is enabled, so the router never
advertises (or 502s on) a path whose backend does not exist in the release.
*/}}
{{- define "router.routes" -}}
{{- $routes := list -}}
{{- if .Values.fileservice.enabled -}}
{{- $routes = append $routes (dict "prefix" "/registry" "service" (include "fileservice.fullname" .) "port" 80) -}}
{{- end -}}
{{- if .Values.identityService.enabled -}}
{{- $routes = append $routes (dict "prefix" "/identity" "service" (include "identity.fullname" .) "port" 80) -}}
{{- end -}}
{{- $routes | toJson -}}
{{- end }}

{{/*
Effective tracing setting for the router, as the string "true" or "false".
`router.tracing.enabled` is tri-state: an explicit true/false wins; unset/null means
"automatic" — tracing follows `jaeger.enabled` so deploying the bundled Jaeger is all
a user has to do (matching how the other services wire up to it).
*/}}
{{- define "router.tracing.enabled" -}}
{{- $jaegerEnabled := dig "enabled" false (default dict .Values.jaeger) -}}
{{- $setting := dig "tracing" "enabled" "" (default dict .Values.router) -}}
{{- if kindIs "bool" $setting -}}
{{- $setting -}}
{{- else -}}
{{- $jaegerEnabled -}}
{{- end -}}
{{- end }}

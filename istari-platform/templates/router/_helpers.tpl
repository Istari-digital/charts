{{/*
Route table for the Service Router, shared by the proxy ConfigMap and NOTES.txt.
Emits a JSON array of {prefix, service, port} objects.

Routes for the platform's own services are managed by the chart: per the
service-router engspec, adding a platform service behind the router is a chart
change, not customer configuration. Each renders only while its backing service is
enabled, so the router never advertises (or 502s on) a path whose backend does not
exist in the release. `router.extraRoutes` entries are appended after strict
validation — the {prefix, service, port} triple is the entire schema, and every
constraint below keeps the table expressible in any of the engspec's sanctioned
proxy implementations, not just the current one.

The final table is sorted longest-prefix-first: Caddy handle blocks and Envoy routes
are first-match-in-declaration-order while nginx picks the longest matching location,
so pre-sorting makes overlap resolution identical however the config is rendered.
*/}}
{{- define "router.routes" -}}
{{- $routes := list -}}
{{- if .Values.fileservice.enabled -}}
{{- $routes = append $routes (dict "prefix" "/registry" "service" (include "fileservice.fullname" .) "port" 80) -}}
{{- end -}}
{{- if .Values.identityService.enabled -}}
{{- $routes = append $routes (dict "prefix" "/identity" "service" (include "identity.fullname" .) "port" 80) -}}
{{- end -}}
{{- range .Values.router.extraRoutes -}}
{{- $prefix := required "router.extraRoutes: every entry needs a prefix" .prefix -}}
{{- if not (regexMatch "^(/[a-zA-Z0-9_-]+)+$" $prefix) -}}
{{- fail (printf "router.extraRoutes: prefix %q is invalid — it must start with \"/\", may not end with \"/\", and its segments may contain only letters, digits, \"-\", and \"_\"" $prefix) -}}
{{- end -}}
{{- if eq $prefix "/healthz" -}}
{{- fail "router.extraRoutes: /healthz is reserved for the router's own health endpoint" -}}
{{- end -}}
{{- $service := required (printf "router.extraRoutes: service is required for prefix %s" $prefix) .service | toString -}}
{{- if not (regexMatch "^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$" $service) -}}
{{- fail (printf "router.extraRoutes: service %q (prefix %s) is not a valid Kubernetes Service name" $service $prefix) -}}
{{- end -}}
{{- $port := int (required (printf "router.extraRoutes: port is required for prefix %s" $prefix) .port) -}}
{{- if or (lt $port 1) (gt $port 65535) -}}
{{- fail (printf "router.extraRoutes: port %v (prefix %s) must be an integer between 1 and 65535" .port $prefix) -}}
{{- end -}}
{{- $routes = append $routes (dict "prefix" $prefix "service" $service "port" $port) -}}
{{- end -}}
{{- $seen := dict -}}
{{- range $routes -}}
{{- if hasKey $seen .prefix -}}
{{- fail (printf "router routes: prefix %s is declared more than once (check router.extraRoutes against the chart-managed routes)" .prefix) -}}
{{- end -}}
{{- $_ := set $seen .prefix true -}}
{{- end -}}
{{- /* Sort longest-prefix-first via zero-padded composite keys; prefixes are unique. */ -}}
{{- $keys := list -}}
{{- $byKey := dict -}}
{{- range $routes -}}
{{- $key := printf "%03d %s" (sub 999 (len .prefix)) .prefix -}}
{{- $_ := set $byKey $key . -}}
{{- $keys = append $keys $key -}}
{{- end -}}
{{- $sorted := list -}}
{{- range sortAlpha $keys -}}
{{- $sorted = append $sorted (get $byKey .) -}}
{{- end -}}
{{- $sorted | toJson -}}
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

{{/*
Route table for the Service Router, shared by the proxy ConfigMap and NOTES.txt.
Emits a JSON array of {prefix, service, port} objects.

Routes for the platform's own services are managed by the chart: per the
service-router engspec, adding a platform service behind the router is a chart
change, not customer configuration. They are always present, whatever this release
enables — the route table is a stable contract for clients, and a prefix whose
backend is not deployed answers 502 at the router. `router.extraRoutes` entries are
appended after strict validation — the {prefix, service, port} triple is the entire
schema, and every constraint below keeps the table expressible in any of the
engspec's sanctioned proxy implementations, not just the current one.

The final table is sorted longest-prefix-first: Caddy handle blocks and Envoy routes
are first-match-in-declaration-order while nginx picks the longest matching location,
so pre-sorting makes overlap resolution identical however the config is rendered.
*/}}
{{- define "router.routes" -}}
{{- $routes := list -}}
{{- $routes = append $routes (dict "prefix" "/registry" "service" (include "fileservice.fullname" .) "port" 80) -}}
{{- $routes = append $routes (dict "prefix" "/identity" "service" (include "identity.fullname" .) "port" 80) -}}
{{- range $entry := .Values.router.extraRoutes -}}
{{- range $key, $unused := $entry -}}
{{- if not (has $key (list "prefix" "service" "port")) -}}
{{- fail (printf "router.extraRoutes: unsupported key %q (entry with prefix %q) — entries accept only prefix, service, and port, and the target Service must be in this release's namespace" $key (default "<unset>" $entry.prefix)) -}}
{{- end -}}
{{- end -}}
{{- $prefix := required "router.extraRoutes: every entry needs a prefix" .prefix -}}
{{- if not (regexMatch "^(/[a-zA-Z0-9_-]+)+$" $prefix) -}}
{{- fail (printf "router.extraRoutes: prefix %q is invalid — it must start with \"/\", may not end with \"/\", and its segments may contain only letters, digits, \"-\", and \"_\"" $prefix) -}}
{{- end -}}
{{- if eq $prefix "/healthz" -}}
{{- fail "router.extraRoutes: /healthz is reserved for the router's own health endpoint" -}}
{{- end -}}
{{- $service := required (printf "router.extraRoutes: service is required for prefix %s" $prefix) .service | toString -}}
{{- if or (gt (len $service) 63) (not (regexMatch "^[a-z]([-a-z0-9]*[a-z0-9])?$" $service)) -}}
{{- fail (printf "router.extraRoutes: service %q (prefix %s) is not a valid Kubernetes Service name (a DNS-1035 label: max 63 chars, lowercase letters, digits, and hyphens, starting with a letter). Use the Service's short name only — dotted/FQDN and cross-namespace targets are not supported, and the Service must live in this release's namespace" $service $prefix) -}}
{{- end -}}
{{- $rawPort := required (printf "router.extraRoutes: port is required for prefix %s" $prefix) .port -}}
{{- $port := int $rawPort -}}
{{- if or (lt $port 1) (gt $port 65535) (ne ($rawPort | toString) ($port | toString)) -}}
{{- fail (printf "router.extraRoutes: port %v (prefix %s) must be a whole number between 1 and 65535" $rawPort $prefix) -}}
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
{{- $key := printf "%04d %s" (sub 9999 (len .prefix)) .prefix -}}
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
{{- else if or (kindIs "invalid" $setting) (eq ($setting | toString) "") -}}
{{- $jaegerEnabled -}}
{{- else -}}
{{- /* A quoted "true"/"false" (or any other non-bool) silently inverting the operator's intent is worse than failing the render. */ -}}
{{- fail (printf "router.tracing.enabled must be true, false, or left unset (null); got %q — quoted strings are not booleans" ($setting | toString)) -}}
{{- end -}}
{{- end }}

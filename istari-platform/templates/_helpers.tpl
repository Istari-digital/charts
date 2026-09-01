{{/*
Expand the name of the chart.
*/}}
{{- define "istari-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | quote }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "istari-platform.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" | quote }}
    {{- else }}
        {{- $name := default .Chart.Name .Values.nameOverride }}
        {{- if contains $name .Release.Name }}
            {{- .Release.Name | trunc 63 | trimSuffix "-" }}
        {{- else }}
            {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" | quote }}
        {{- end }}
    {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "istari-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
{{- end }}

{{/*
In-cluster NATS connection URL. Resolves to `nats://<nats-service-name>:4222`. The service name mirrors the NATS subchart's own `nats.fullname` helper so this URL stays in sync regardless of whether the user sets `nats.fullnameOverride`, `nats.nameOverride`, or relies on the release-name-based default.

Logic, in order:
  1. `nats.fullnameOverride` set → use it, with `trunc 63 | trimSuffix "-"` to match the subchart.
  2. Release name already contains the NATS name (`nats.nameOverride`, defaulting to `nats`) → use release name alone (subchart's "don't double-up" rule).
  3. Otherwise → `<release>-<natsName>`, trunc/trimmed.

Used by templates that auto-inject `FILE_SERVICE_NATS_URL` when `nats.enabled` is true.
*/}}
{{- define "istari-platform.nats.url" -}}
{{- $natsValues := .Values.nats -}}
{{- $fullname := "" -}}
{{- if $natsValues.fullnameOverride -}}
  {{- $fullname = $natsValues.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $natsName := default "nats" $natsValues.nameOverride -}}
  {{- if contains $natsName .Release.Name -}}
    {{- $fullname = .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $fullname = printf "%s-%s" .Release.Name $natsName | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}
{{- printf "nats://%s:4222" $fullname -}}
{{- end }}

{{/*
NATS-related env entries injected into the fileservice main container, init-db initContainer, and migration Job when `nats.enabled` is true. Centralized here so the env list stays in sync across all three workloads — add new NATS-dependent env vars in one place.

Renders no leading conditional; callers gate the include behind their own `if $natsEnabled` so the surrounding `env:` key only appears when something actually needs to be set.
*/}}
{{- define "istari-platform.fileservice.natsEnv" -}}
- name: FILE_SERVICE_NATS_URL
  value: {{ include "istari-platform.nats.url" . | quote }}
- name: FILE_SERVICE_ALLOWED_IDS_CACHE_ENABLED
  value: "true"
{{- end }}

{{/*
Name of the Jaeger Service created by the subchart. Must mirror the subchart's own
`jaeger.fullname` helper (fullnameOverride, else nameOverride/release-name rules) so the name
stays in sync however the user overrides naming.
*/}}
{{- define "istari-platform.jaeger.fullname" -}}
{{- $jaegerValues := default dict .Values.jaeger -}}
{{- if $jaegerValues.fullnameOverride -}}
  {{- $jaegerValues.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $jaegerName := default "jaeger" $jaegerValues.nameOverride -}}
  {{- if contains $jaegerName .Release.Name -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name $jaegerName | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
In-cluster Jaeger OTLP gRPC URL. Resolves to `http://<jaeger-service-name>:4317` via the fullname helper above. Used by templates that auto-inject `OTEL_EXPORTER_OTLP_ENDPOINT` for gRPC exporters (fileservice) when `jaeger.enabled` is true.
*/}}
{{- define "istari-platform.jaeger.otlpUrl" -}}
{{- printf "http://%s:4317" (include "istari-platform.jaeger.fullname" .) -}}
{{- end }}

{{/*
In-cluster Jaeger OTLP HTTP URL. Resolves to `http://<jaeger-service-name>:4318` via the fullname helper above. Used by templates that auto-inject `OTEL_EXPORTER_OTLP_ENDPOINT` for OTLP/HTTP exporters (the Identity Service) when `jaeger.enabled` is true.
*/}}
{{- define "istari-platform.jaeger.otlpHttpUrl" -}}
{{- printf "http://%s:4318" (include "istari-platform.jaeger.fullname" .) -}}
{{- end }}

{{/*
Per-workload identity env, shared by every container of every OTEL-emitting service (web, init,
and migration Job). Always emits four downward-API building blocks — POD_NAME, POD_NAMESPACE,
POD_UID (fieldRef) and a literal CONTAINER_NAME — so service code, third-party sidecars, and
users can enrich telemetry off them regardless of tracing. Container name has no downward-API
fieldRef, so CONTAINER_NAME is the literal `.containerName` the chart knows at render time.

When `.jaegerEnabled`, it additionally sets a chart-default OTEL_SERVICE_NAME
(`<service>.<subservice>`) and OTEL_RESOURCE_ATTRIBUTES built from those `$(VAR)` blocks, so
traces carry accurate Kubernetes identity with zero user config. A user's own
OTEL_RESOURCE_ATTRIBUTES — set in `<service>.env` or `<service>.migrations.env`, and free to
reference the same `$(VAR)`s — overrides this default.

`$(VAR)` expands only against env defined earlier in the SAME container and NOT against values
delivered via `envFrom`, so these blocks must be explicit env and must precede any var that
references them. Callers therefore render this FIRST, then user env, then pass the whole list
through "istari-platform.dedupeEnv": on a repeated name the later (user) entry wins, collapsing
to one entry — kubelet already takes the last value, and a single entry is what client-side
strategic-merge patches (Argo CD's diff) require, since they key env by name and reject
duplicates.

Context: dict of "service", "subservice", "containerName", "jaegerEnabled".
*/}}
{{- define "istari-platform.workloadIdentityEnv" -}}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_UID
  valueFrom:
    fieldRef:
      fieldPath: metadata.uid
- name: CONTAINER_NAME
  value: {{ .containerName | quote }}
{{- if .jaegerEnabled }}
- name: OTEL_SERVICE_NAME
  value: {{ printf "%s.%s" .service .subservice | quote }}
- name: OTEL_RESOURCE_ATTRIBUTES
  value: "k8s.pod.name=$(POD_NAME),k8s.namespace.name=$(POD_NAMESPACE),k8s.pod.uid=$(POD_UID),k8s.container.name=$(CONTAINER_NAME)"
{{- end }}
{{- end }}

{{/*
Collapse an env list to unique names: each name is emitted once, at the position of its FIRST
occurrence, carrying the value of its LAST occurrence. Last-value matches kubelet (which resolves
a repeated env name to its last value) so a user entry still overrides an earlier chart default;
first-position keeps a name stable where the chart first placed it, so the downward-API building
blocks stay ahead of the `$(VAR)`-referencing vars even when a user overrides one of the blocks
(a later user POD_NAME/CONTAINER_NAME must NOT jump past the OTEL_RESOURCE_ATTRIBUTES that
references it, or Kubernetes leaves the reference an unexpanded literal). Emitting each name once
is also what makes the manifest patchable by a client-side strategic merge (Argo CD's diff),
which keys env by name and rejects duplicates.

Input: a list of env maps (each with a `name`). Output: YAML for the deduped list.
*/}}
{{- define "istari-platform.dedupeEnv" -}}
{{- $entries := . -}}
{{- $lastByName := dict -}}
{{- range $e := $entries -}}
{{- $_ := set $lastByName $e.name $e -}}
{{- end -}}
{{- $seen := dict -}}
{{- $out := list -}}
{{- range $e := $entries -}}
{{- if not (hasKey $seen $e.name) -}}
{{- $_ := set $seen $e.name true -}}
{{- $out = append $out (index $lastByName $e.name) -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end }}

{{/*
Env that points common TLS/CA-bundle libraries at the mounted trusted-cert bundle. Injected
into every service container when `.Values.trustedCertBundle` is set. Centralized so the paths
stay in sync across web, init, and migration workloads.
*/}}
{{- define "istari-platform.trustedCertEnv" -}}
- name: GRPC_DEFAULT_SSL_ROOTS_FILE_PATH
  value: /usr/lib/ssl/cert.pem
- name: REQUESTS_CA_BUNDLE
  value: /usr/lib/ssl/cert.pem
- name: SSL_CERT_DIR
  value: /usr/lib/ssl/certs
- name: SSL_CERT_FILE
  value: /usr/lib/ssl/cert.pem
{{- end }}

{{/*
Resolved API Gateway base URL, or "" when the gateway contract is off.
Only apiGateway.apiUrl activates the contract — this chart never derives one
value's default from another, so a release that deploys the API Gateway with an
Ingress still needs apiUrl set explicitly. Trailing slashes and surrounding
whitespace are stripped, so <base>/registry never renders a double slash.
*/}}
{{- define "istari-platform.apiGatewayUrl" -}}
{{- $r := default dict .Values.apiGateway -}}
{{- trimSuffix "/" (trim (default "" $r.apiUrl)) -}}
{{- end }}

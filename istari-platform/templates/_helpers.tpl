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
{{- $natsValues := default dict .Values.nats -}}
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
In-cluster Jaeger OTLP HTTP URL. Resolves to `http://<jaeger-service-name>:4318` via the fullname helper above. Used by templates that auto-inject `OTEL_EXPORTER_OTLP_ENDPOINT` for OTLP/HTTP exporters (identity-service) when `jaeger.enabled` is true.
*/}}
{{- define "istari-platform.jaeger.otlpHttpUrl" -}}
{{- printf "http://%s:4318" (include "istari-platform.jaeger.fullname" .) -}}
{{- end }}

{{/*
Per-workload OTEL identity for init/migration containers, named `<service>.<subservice>`.
Context is a dict of "service" and "container" (the container name doubles as the subservice);
web containers get their identity from their service's defaults ConfigMap instead. Explicit env
so it overrides that ConfigMap, rendered BEFORE user `env` so the service's `env` values still
win (Secrets can't override these two). Callers gate behind their own `if $jaegerEnabled`.
*/}}
{{- define "istari-platform.otelWorkloadEnv" -}}
- name: OTEL_SERVICE_NAME
  value: {{ printf "%s.%s" .service .container | quote }}
- name: OTEL_RESOURCE_ATTRIBUTES
  value: {{ printf "k8s.container.name=%s" .container | quote }}
{{- end }}

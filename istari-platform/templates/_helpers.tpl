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

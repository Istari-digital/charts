{{/*
Expand the name of the chart.
*/}}
{{- define "istari-zitadel-configurator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "istari-zitadel-configurator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "istari-zitadel-configurator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "istari-zitadel-configurator.labels" -}}
helm.sh/chart: {{ include "istari-zitadel-configurator.chart" . }}
{{ include "istari-zitadel-configurator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
sidecar.istio.io/inject: "false"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "istari-zitadel-configurator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "istari-zitadel-configurator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "istari-zitadel-configurator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "istari-zitadel-configurator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "istari-zitadel-configurator-zitadel-url" -}}
{{- if .Values.configurator.zitadel_insecure }}
http://{{ include "istari-zitadel-configurator-zitadel-domain" . }}:{{ .Values.configurator.zitadel_port }}
{{- else }}
https://{{ include "istari-zitadel-configurator-zitadel-domain" . }}:{{ .Values.configurator.zitadel_port }}
{{- end }}
{{- end }}

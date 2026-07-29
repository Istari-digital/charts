{{/*
Selector labels
*/}}
{{- define "router.selectorLabels" -}}
app.kubernetes.io/component: "router"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "router.labels" -}}
{{ include "router.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.router.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

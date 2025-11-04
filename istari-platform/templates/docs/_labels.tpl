{{/*
Selector labels
*/}}
{{- define "docs.selectorLabels" -}}
app.kubernetes.io/component: "docs"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "docs.labels" -}}
{{ include "docs.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.docs.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

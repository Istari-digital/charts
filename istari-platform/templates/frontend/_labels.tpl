{{/*
Selector labels
*/}}
{{- define "frontend.selectorLabels" -}}
app.kubernetes.io/component: "frontend"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "frontend.labels" -}}
{{ include "frontend.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.frontend.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

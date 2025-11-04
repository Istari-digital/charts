{{/*
Selector labels
*/}}
{{- define "fileservice.selectorLabels" -}}
app.kubernetes.io/component: "fileservice"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fileservice.labels" -}}
{{ include "fileservice.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.fileservice.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

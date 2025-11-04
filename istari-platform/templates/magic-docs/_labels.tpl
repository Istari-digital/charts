{{/*
Selector labels
*/}}
{{- define "magic-docs.selectorLabels" -}}
app.kubernetes.io/component: "magic-docs"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "magic-docs.labels" -}}
{{ include "magic-docs.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.magicDocs.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mcp.selectorLabels" -}}
app.kubernetes.io/component: "mcp"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mcp.labels" -}}
{{ include "mcp.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.mcp.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

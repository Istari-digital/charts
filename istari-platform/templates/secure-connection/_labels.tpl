{{/*
Selector labels
*/}}
{{- define "secure-connection.selectorLabels" -}}
app.kubernetes.io/component: "secure-connection"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "secure-connection.labels" -}}
{{ include "secure-connection.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.secureConnection.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

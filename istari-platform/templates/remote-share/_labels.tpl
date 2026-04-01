{{/*
Selector labels
*/}}
{{- define "remote-share.selectorLabels" -}}
app.kubernetes.io/component: "remote-share"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "remote-share.labels" -}}
{{ include "remote-share.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.remoteShare.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

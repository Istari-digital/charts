{{/*
Selector labels
*/}}
{{- define "provisioner.selectorLabels" -}}
app.kubernetes.io/component: "provisioner"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "provisioner.labels" -}}
{{ include "provisioner.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.provisioner.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

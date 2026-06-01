{{/*
Selector labels
*/}}
{{- define "identity-service.selectorLabels" -}}
app.kubernetes.io/component: "identity-service"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "istari-platform.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-service.labels" -}}
{{ include "identity-service.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ include "istari-platform.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.identityService.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

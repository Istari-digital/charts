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

{{/*
Labels for the provisioning Job's pod template.

This is `provisioner.labels` minus the two volatile standard labels, `helm.sh/chart` and
`app.kubernetes.io/version`. The Job name is a hash that includes the pod template (see
`provisioner.podTemplate`), and a Job's `spec.template` is immutable, so any label that changed on
a chart-version bump would force the Job to rename -- and rerun -- on every upgrade, even one that
changes no provisioner input. The Job's own object labels keep the full set for discoverability;
only the pod template and the labels Terraform stamps onto the generated Secrets drop the pair.
*/}}
{{- define "provisioner.podLabels" -}}
{{ include "provisioner.selectorLabels" . }}
app.kubernetes.io/managed-by: "Helm"
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.provisioner.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

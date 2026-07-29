{{/*
Default name/prefix for service-router resources.
DELIBERATE: the two "router" literals below are retained on purpose. Renaming
them would rename the rendered Deployment/Service/ConfigMap from "istari-router"
to something else, and Argo diffs a release by the manifests it produces — a
renamed object is deleted and recreated, not relabeled. dev and infra run this
gateway live with their Argo Applications on a floating 3.* pin, so this would
tear down and rebuild a live gateway unattended. Do not "fix" this to match
serviceRouter.
*/}}
{{- define "serviceRouter.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "router" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "router" | trunc 63 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
serviceRouter proxy-config configmap name. Deliberately proxy-agnostic (not
"-caddyfile"): swapping the proxy implementation must not rename chart resources.
*/}}
{{- define "serviceRouter.configmap.name" -}}
{{ printf "%s-config" (include "serviceRouter.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

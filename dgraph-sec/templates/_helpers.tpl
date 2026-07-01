{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dgraph-sec.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 -}}
{{- end -}}
{{/*
Create a default fully qualified app name.
We truncate at 24 chars for parity with the upstream chart and its helper scripts, which assume a 24-char fullname. This is not a DNS limit — DNS labels allow 63 chars.
*/}}
{{- define "dgraph-sec.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 24 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dgraph-sec.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified data name.
*/}}
{{- define "dgraph-sec.zero.fullname" -}}
{{ template "dgraph-sec.fullname" . }}-{{ .Values.zero.name }}
{{- end -}}

{{/*
Create a default fully qualified data name.
*/}}
{{- define "dgraph-sec.backups.fullname" -}}
{{ template "dgraph-sec.fullname" . }}-{{ .Values.backups.name }}
{{- end -}}

{{/*
Return the backups image name
*/}}
{{- define "dgraph-sec.backups.image" -}}
{{- $registryName := .Values.backups.image.registry -}}
{{- $repositoryName := .Values.backups.image.repository -}}
{{- $tag := .Values.backups.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Return the ratel image name
*/}}
{{- define "dgraph-sec.ratel.image" -}}
{{- $registryName := .Values.ratel.image.registry -}}
{{- $repositoryName := .Values.ratel.image.repository -}}
{{- $tag := .Values.ratel.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}


{{/*
Return empty string if minio keys are not defined
*/}}
{{- define "dgraph-sec.backups.keys.minio.enabled" -}}
{{- $minioEnabled := "" -}}
{{- $backupsEnabled := or .Values.backups.full.enabled .Values.backups.incremental.enabled }}
{{- if $backupsEnabled -}}
  {{- if .Values.backups.keys -}}
    {{- if .Values.backups.keys.minio -}}
      {{- if and .Values.backups.keys.minio.access .Values.backups.keys.minio.secret -}}
        {{- $minioEnabled = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $minioEnabled -}}
{{- end -}}

{{/*
Return empty string if s3 keys are not defined
*/}}
{{- define "dgraph-sec.backups.keys.s3.enabled" -}}
{{- $s3Enabled := "" -}}
{{- $backupsEnabled := or .Values.backups.full.enabled .Values.backups.incremental.enabled }}
{{- if $backupsEnabled -}}
  {{- if .Values.backups.keys -}}
    {{- if .Values.backups.keys.s3 -}}
      {{- if and .Values.backups.keys.s3.access .Values.backups.keys.s3.secret -}}
        {{- $s3Enabled = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $s3Enabled -}}
{{- end -}}

{{/*
Return the initContainers image name
*/}}
{{- define "dgraph-sec.initContainers.init.image" -}}
{{- $registryName := .Values.alpha.initContainers.init.image.registry -}}
{{- $repositoryName := .Values.alpha.initContainers.init.image.repository -}}
{{- $tag := .Values.alpha.initContainers.init.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Return the proper image name (for the metrics image)
*/}}
{{- define "dgraph-sec.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 doesn't support it, so we need to implement this if-else logic.
Also, we can't use a single if because lazy evaluation is not an option
*/}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
        {{- printf "%s/%s:%s" .Values.global.imageRegistry $repositoryName $tag -}}
    {{- else -}}
        {{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
Priority: imagePullSecrets (K8s object list) > global.imagePullSecrets (string list) > image.pullSecrets (string list)
*/}}
{{- define "dgraph-sec.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.imagePullSecrets }}
{{- if kindIs "map" . }}
  - name: {{ .name }}
{{- else }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- else if and .Values.global .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- else if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified alpha name.
*/}}
{{- define "dgraph-sec.alpha.fullname" -}}
{{ template "dgraph-sec.fullname" . }}-{{ .Values.alpha.name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "dgraph-sec.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dgraph-sec.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified ratel name.
*/}}
{{- define "dgraph-sec.ratel.fullname" -}}
{{ template "dgraph-sec.fullname" . }}-{{ .Values.ratel.name }}
{{- end -}}

{{/*
Build a complete label set as a dict and render via toYaml so that keys
are always sorted alphabetically by Go's YAML marshaler.

Parameters (passed as a dict):
  ctx        — the Helm root context (required)
  component  — value for component / app.kubernetes.io/component (optional)
  extra      — dict of additional chart-defined labels, e.g. monitor or cronjob (optional)
  podLabels  — dict of user-supplied per-component pod labels (optional)

On key conflicts, higher-priority sources override lower-priority ones:
  (lowest)  commonLabels  — from values.yaml, applied to every resource
            podLabels     — from values.yaml, only passed on pod templates
            extra         — chart-defined, only passed by specific templates
            component     — chart-defined, omitted on shared resources like the ServiceAccount
  (highest) standard labels (app, chart, release, heritage, app.kubernetes.io/*)

For example, commonLabels cannot override standard labels like "app" or
"release", and podLabels cannot override chart-defined extra labels.

Not every call passes every parameter. The "extra" parameter is only
used by templates that need additional chart-defined labels:
  - alpha/zero non-headless Services pass extra.monitor (from monitorLabel)
  - alpha/zero headless Services pass extra from serviceHeadless.labels
  - ratel Service passes extra from service.labels
  - backup CronJob pod templates pass extra.cronjob
The "component" parameter is omitted on the shared ServiceAccount and
the pre-upgrade hook resources (which aren't component-specific).

Note on monitorLabel: because "monitor" is only passed as an extra on
the two non-headless Services, setting commonLabels.monitor will add a
"monitor" label to most resources, but those two Services will still
show their chart-defined monitorLabel value instead.
*/}}
{{- define "dgraph-sec.labels" -}}
{{- $ctx := .ctx -}}
{{- $labels := default (dict) $ctx.Values.commonLabels | deepCopy -}}
{{- $_ := deepCopy (default (dict) .podLabels) | mergeOverwrite $labels -}}
{{- range $key, $val := (default (dict) .extra) -}}
{{- $_ := set $labels $key $val -}}
{{- end -}}
{{- if .component -}}
{{- $_ := set $labels "app.kubernetes.io/component" .component -}}
{{- $_ := set $labels "component" .component -}}
{{- end -}}
{{- $_ := set $labels "app" (include "dgraph-sec.name" $ctx) -}}
{{- $_ := set $labels "app.kubernetes.io/instance" $ctx.Release.Name -}}
{{- $_ := set $labels "app.kubernetes.io/managed-by" $ctx.Release.Service -}}
{{- $_ := set $labels "app.kubernetes.io/name" (include "dgraph-sec.name" $ctx) -}}
{{- if $ctx.Chart.AppVersion -}}
{{- $_ := set $labels "app.kubernetes.io/version" $ctx.Chart.AppVersion -}}
{{- end -}}
{{- $_ := set $labels "chart" (include "dgraph-sec.chart" $ctx) -}}
{{- $_ := set $labels "helm.sh/chart" (include "dgraph-sec.chart" $ctx) -}}
{{- $_ := set $labels "heritage" $ctx.Release.Service -}}
{{- $_ := set $labels "release" $ctx.Release.Name -}}
{{- toYaml $labels -}}
{{- end -}}

{{/*
Allow overriding namespace
*/}}
{{- define "dgraph-sec.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}

{{/*
Render Datadog autodiscovery annotations for a component.
Follows the Istari 3-tier naming convention:
  superservice (e.g. dgraph-sec)
  subservice   (e.g. alpha, zero)
  full_service (e.g. dgraph-sec.alpha)

The per-container annotation keys (e.g. ad.datadoghq.com/<name>.logs) must
use the actual K8s container name, which is the chart fullname + component
(e.g. my-release-dgraph-sec-alpha).

Parameters (passed as a dict):
  ctx       — the Helm root context (required)
  component — "alpha" or "zero" (required)
*/}}
{{- define "dgraph-sec.datadogAnnotations" -}}
{{- $superservice := .ctx.Values.datadog.superservice -}}
{{- $subservice := "" -}}
{{- $containerName := "" -}}
{{- if eq .component "alpha" -}}
{{- $subservice = .ctx.Values.datadog.alpha.subservice -}}
{{- $containerName = include "dgraph-sec.alpha.fullname" .ctx | trim -}}
{{- else -}}
{{- $subservice = .ctx.Values.datadog.zero.subservice -}}
{{- $containerName = include "dgraph-sec.zero.fullname" .ctx | trim -}}
{{- end -}}
{{- $fullService := printf "%s.%s" $superservice $subservice -}}
ad.datadoghq.com/tags: {{ printf `'{"istari_superservice":"%s","istari_subservice":"%s","istari_full_service":"%s"}'` $superservice $subservice $fullService }}
ad.datadoghq.com/{{ $containerName }}.logs: {{ printf `'[{"source":"dgraph","service":"%s"}]'` $fullService }}
ad.datadoghq.com/{{ $containerName }}.tags: {{ printf `'{"istari_full_service":"%s"}'` $fullService }}
ad.datadoghq.com/istio-proxy.logs: {{ printf `'[{"source":"envoy","service":"%s"}]'` $fullService }}
ad.datadoghq.com/istio-proxy.tags: {{ printf `'{"istari_full_service":"%s"}'` $fullService }}
ad.datadoghq.com/istio-init.logs: {{ printf `'[{"source":"envoy","service":"%s"}]'` $fullService }}
ad.datadoghq.com/istio-init.tags: {{ printf `'{"istari_full_service":"%s"}'` $fullService }}
{{- end -}}

{{/*
Render Datadog unified service tag labels for a component.

The per-container label keys use the actual K8s container name.

Parameters (passed as a dict):
  ctx       — the Helm root context (required)
  component — "alpha" or "zero" (required)
*/}}
{{- define "dgraph-sec.datadogLabels" -}}
{{- $superservice := .ctx.Values.datadog.superservice -}}
{{- $subservice := "" -}}
{{- $containerName := "" -}}
{{- if eq .component "alpha" -}}
{{- $subservice = .ctx.Values.datadog.alpha.subservice -}}
{{- $containerName = include "dgraph-sec.alpha.fullname" .ctx | trim -}}
{{- else -}}
{{- $subservice = .ctx.Values.datadog.zero.subservice -}}
{{- $containerName = include "dgraph-sec.zero.fullname" .ctx | trim -}}
{{- end -}}
{{- $fullService := printf "%s.%s" $superservice $subservice -}}
tags.datadoghq.com/service: {{ $fullService }}
tags.datadoghq.com/{{ $containerName }}.service: {{ $fullService }}
{{- end -}}

{{- /* Generate ingress path */}}
{{- define "dgraph-sec.ingressPath" -}}
  {{- $path := "/" -}}
  {{- if .Values.global.ingress.ingressClassName -}}
    {{- if eq .Values.global.ingress.ingressClassName "gce" "alb" "nsx" }}
      {{- $path = "/*" -}}
    {{- else }}
      {{- $path = "/" -}}
    {{- end }}
  {{- else if index $.Values.global.ingress "annotations" -}}
    {{- if eq (index $.Values.global.ingress.annotations "kubernetes.io/ingress.class" | default "") "gce" "alb" "nsx" }}
      {{- $path = "/*" -}}
    {{- else }}
      {{- $path = "/" -}}
    {{- end }}
  {{- end -}}
  {{- printf "%s" $path -}}
{{- end -}}

{{- /* Backup API type. Dgraph v20.03.1+ uses the GraphQL /admin endpoint;
       this is a v25.x fork so GraphQL is always correct. override_api_type
       remains an escape hatch. */}}
{{- define "dgraph-sec.backupsApiType" -}}
{{- if .Values.backups.override_api_type -}}
  {{- printf "%s" .Values.backups.override_api_type -}}
{{- else -}}
  {{- printf "graphql" -}}
{{- end -}}
{{- end -}}

{{- /* Generate domain name for first zero in cluster */}}
{{- define "dgraph-sec.peerZero" -}}
  {{- $zeroFullName := include "dgraph-sec.zero.fullname" . -}}

  {{- /* Append the cluster-domain suffix (trimmed, omitted when empty). */}}
  {{- $domainSuffix := include "dgraph-sec.domainSuffix" . -}}

  {{- printf "%s-%d.%s-headless.${POD_NAMESPACE}.svc%s:5080" $zeroFullName 0 $zeroFullName $domainSuffix -}}
{{- end -}}

{{- /* Raft index flag. v21.03.0+ uses the `--raft idx=` superflag; this is a
       v25.x fork so the superflag form is always correct. */}}
{{- define "dgraph-sec.raftIndexFlag" -}}
  {{- printf "--raft idx=" -}}
{{- end -}}

{{- /* Map a named log level to its glog -v integer; pass any other value
       (e.g. a raw integer) through unchanged. Names are lowercase. */}}
{{- define "dgraph-sec.verbosity" -}}
  {{- $m := dict "normal" "0" "verbose" "1" "debug" "2" "trace" "3" -}}
  {{- $k := toString . -}}
  {{- index $m $k | default $k -}}
{{- end -}}

{{- /* Render the glog flag fragment for a role. `.` is a role value map
       (.Values.alpha or .Values.zero). logLevel and logtostderr always emit;
       vmodule/alsologtostderr/logDir emit only when set. */}}
{{- define "dgraph-sec.logFlags" -}}
-v={{ include "dgraph-sec.verbosity" .logLevel }} --logtostderr={{ .logtostderr }}{{ if .vmodule }} --vmodule={{ .vmodule }}{{ end }}{{ if .alsologtostderr }} --alsologtostderr{{ end }}{{ if .logDir }} --log_dir={{ .logDir }}{{ end }}
{{- end -}}

{{- /* Generate comma-separated list of Zeros */}}
{{- define "dgraph-sec.multiZeros" -}}
  {{- $zeroFullName := include "dgraph-sec.zero.fullname" . -}}
  {{- $max := int .Values.zero.replicaCount -}}

  {{- /* Append the cluster-domain suffix (trimmed, omitted when empty). */}}
  {{- $domainSuffix := include "dgraph-sec.domainSuffix" . -}}

  {{- /* Create comma-separated list of zeros */}}
  {{- range $idx := until $max }}
    {{- printf "%s-%d.%s-headless.${POD_NAMESPACE}.svc%s:5080" $zeroFullName $idx $zeroFullName $domainSuffix -}}
    {{- if ne $idx (sub $max 1) -}}
      {{- print "," -}}
    {{- end -}}
  {{ end }}
{{- end -}}

{{- /* native-TLS-active for a tier: no service mesh AND the tier's TLS is on.
       Pass a dict {"ctx": ., "tls": .Values.alpha.tls}.
       Returns the STRING "true" or "" (empty) -- NOT a boolean. Compare it as a
       string: eq (include "dgraph-sec.nativeTLS" ...) "true". Callers should
       generally store that result once in a $nativeTLS bool and reuse it, though
       a few inline the include directly. It is the single predicate
       that gates --tls synthesis, the HTTPS probe scheme, the ACL bootstrap Job's
       TLS client, and the backup CronJobs' TLS client (CACERT, HTTPS, and the
       cert-Secret mount). The alpha-0 headless FQDN those Jobs target is set
       unconditionally, not gated by this. */}}
{{- define "dgraph-sec.nativeTLS" -}}
{{- if and (not .ctx.Values.serviceMesh.enabled) .tls.enabled -}}true{{- end -}}
{{- end -}}

{{- /* Cluster-domain suffix for in-cluster FQDNs: ".<global.domain>" with the
       leading dot, or empty when global.domain is unset. Trims stray leading/
       trailing dots so a host never renders "...svc." or "...svc..cluster.local".
       Use as: ...svc{{ include "dgraph-sec.domainSuffix" . }} */}}
{{- define "dgraph-sec.domainSuffix" -}}
{{- with (.Values.global.domain | default "" | trimAll ".") }}.{{ . }}{{ end -}}
{{- end -}}

{{- /* Compose Dgraph's --tls superflag from a tier's tls map. Pass a dict
       {"tls": .Values.alpha.tls, "path": "/dgraph/tls"}. Filenames follow the
       output of scripts/make_tls_secrets.sh (ca.crt, node.crt, node.key,
       client.<name>.crt/.key). client-cert/key and client-auth-type are emitted
       only when the corresponding values are set. */}}
{{- define "dgraph-sec.tlsFlag" -}}
{{- /* internalPort defaults to true (values.yaml), but Helm's `default` treats a
       boolean false as empty, so an explicit `false` would be flipped back to the
       default. Use a nil check so nil -> true while honoring an explicit false. */ -}}
{{- $ip := .tls.internalPort -}}
{{- if kindIs "invalid" $ip -}}{{- $ip = true -}}{{- end -}}
{{- $opts := list (printf "ca-cert=%s/ca.crt" .path) (printf "server-cert=%s/node.crt" .path) (printf "server-key=%s/node.key" .path) (printf "internal-port=%v" $ip) -}}
{{- if .tls.clientName -}}
{{- $opts = append $opts (printf "client-cert=%s/client.%s.crt" .path .tls.clientName) -}}
{{- $opts = append $opts (printf "client-key=%s/client.%s.key" .path .tls.clientName) -}}
{{- end -}}
{{- if .tls.clientAuthType -}}
{{- $opts = append $opts (printf "client-auth-type=%s" .tls.clientAuthType) -}}
{{- end -}}
{{- printf "--tls \"%s;\"" (join "; " $opts) -}}
{{- end -}}

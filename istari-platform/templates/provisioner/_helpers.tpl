{{/*
The provisioning Job's full pod template (`metadata` + `spec`), rendered identically for the Job
manifest and for the Job's name hash.

Everything here must be deterministic -- no `.Release.Revision`, timestamps, or random values, and
no chart-version labels (see `provisioner.podLabels`). The Job name embeds `sha256sum` of this
block, so a changed input produces a new name: Helm prunes the old Job and the new one reruns.
That is how the provisioner picks up changed inputs without ever hitting the Job `spec.template`
immutability error that an in-place `helm upgrade` of a fixed-name Job would raise.
*/}}
{{- define "provisioner.podTemplate" -}}
{{- $provisioner := .Values.provisioner }}
{{- $gatewayUrl := include "istari-platform.apiGatewayUrl" . }}
{{- $identityServiceUrl := "" }}
{{- if $gatewayUrl }}{{- $identityServiceUrl = printf "%s/identity" $gatewayUrl }}{{- end }}
{{- $common := default dict .Values.common }}
{{- $mainFqdn := trim (default "" $common.mainFqdn) }}
{{- $mcpHost := trim (default "" $common.mcpFqdnOverride) }}
{{- if and (not $mcpHost) $mainFqdn }}{{- $mcpHost = printf "mcp.%s" $mainFqdn }}{{- end }}
{{- $frontendRedirect := "" }}
{{- if $mainFqdn }}{{- $frontendRedirect = printf "https://%s" $mainFqdn }}{{- end }}
{{- $mcpRedirect := "" }}
{{- if $mcpHost }}{{- $mcpRedirect = printf "https://%s/auth/callback" $mcpHost }}{{- end }}
{{/*
The chart computes the frontend/mcp redirect URIs from `common` and passes them as
TF_VAR_*_redirect_uri. The *_enabled and *_extra_redirect_uris vars are constants (all three clients
always register; extra redirects are supplied to identity-service directly), and TF_VAR_main_domain
is now redundant -- the image only falls back to deriving a redirect from it when the passed
redirect is empty, which is exactly when mainFqdn is unset, so it never changes the result. The image
still declares *_enabled, *_extra_redirect_uris, and main_domain; TODO(INF-1784) removes them there
(along with the image-side redirect derivation), after which these pass-through lines go.
*/}}
{{- $tfVars := list
  (dict "name" "TF_VAR_common_labels" "value" (include "provisioner.podLabels" . | fromYaml | toJson))
  (dict "name" "TF_VAR_frontend_enabled" "value" "true")
  (dict "name" "TF_VAR_frontend_extra_redirect_uris" "value" "[]")
  (dict "name" "TF_VAR_frontend_redirect_uri" "value" $frontendRedirect)
  (dict "name" "TF_VAR_frontend_secret_name" "value" (include "provisioner.frontendSecretName" .))
  (dict "name" "TF_VAR_identity_platform_clients_secret_name" "value" (include "provisioner.identityPlatformClientsSecretName" .))
  (dict "name" "TF_VAR_identity_service_url" "value" $identityServiceUrl)
  (dict "name" "TF_VAR_main_domain" "value" $mainFqdn)
  (dict "name" "TF_VAR_mcp_enabled" "value" "true")
  (dict "name" "TF_VAR_mcp_extra_redirect_uris" "value" "[]")
  (dict "name" "TF_VAR_mcp_redirect_uri" "value" $mcpRedirect)
  (dict "name" "TF_VAR_mcp_secret_name" "value" (include "provisioner.mcpSecretName" .))
  (dict "name" "TF_VAR_namespace" "value" .Release.Namespace)
  (dict "name" "TF_VAR_registry_enabled" "value" "true")
  (dict "name" "TF_VAR_registry_secret_name" "value" (include "provisioner.registrySecretName" .))
  (dict "name" "TF_VAR_service_account_name" "value" (include "provisioner.fullname" .))
-}}
{{- $env := include "istari-platform.dedupeEnv" (concat $tfVars $provisioner.env) }}
metadata:
  labels:
    {{- include "provisioner.podLabels" . | nindent 4 }}
  {{- with $provisioner.podAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  restartPolicy: Never
  serviceAccountName: {{ include "provisioner.fullname" . | quote }}
  {{- with $provisioner.podSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with default $.Values.imagePullSecrets $provisioner.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  # The image has no shell -- exec-form args only. init/apply are separate containers, not a
  # shell script; plan-vs-apply is chosen at render time (provisioner.planOnly).
  initContainers:
  - name: terraform-init
    image: {{ printf "%s/%s:%s" $provisioner.registry $provisioner.image $provisioner.tag | quote }}
    imagePullPolicy: {{ $provisioner.imagePullPolicy | quote }}
    {{- with $provisioner.containerSecurityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    args:
    - "-chdir=/terraform"
    - "init"
    - "-input=false"
    - {{ printf "-backend-config=secret_suffix=%s" (include "provisioner.stateSecretSuffix" .) | quote }}
    - {{ printf "-backend-config=namespace=%s" .Release.Namespace | quote }}
    - "-backend-config=in_cluster_config=true"
    env:
    {{- $env | nindent 4 }}
    {{- with $provisioner.extraEnvSecrets }}
    envFrom:
    {{- range . }}
    - secretRef:
        name: {{ . | quote }}
    {{- end }}
    {{- end }}
    volumeMounts:
    - name: terraform-work
      mountPath: /work/.terraform
    {{- with $provisioner.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  containers:
  - name: provisioner
    image: {{ printf "%s/%s:%s" $provisioner.registry $provisioner.image $provisioner.tag | quote }}
    imagePullPolicy: {{ $provisioner.imagePullPolicy | quote }}
    {{- with $provisioner.containerSecurityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    args:
    - "-chdir=/terraform"
    {{- if $provisioner.planOnly }}
    - "plan"
    - "-input=false"
    {{- else }}
    - "apply"
    - "-input=false"
    - "-auto-approve"
    {{- end }}
    env:
    {{- $env | nindent 4 }}
    {{- with $provisioner.extraEnvSecrets }}
    envFrom:
    {{- range . }}
    - secretRef:
        name: {{ . | quote }}
    {{- end }}
    {{- end }}
    volumeMounts:
    - name: terraform-work
      mountPath: /work/.terraform
    {{- with $provisioner.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  volumes:
  # .tf files are baked into the image at /terraform. This emptyDir is just Terraform's
  # writable state dir (TF_DATA_DIR), shared between the init and apply containers.
  - name: terraform-work
    emptyDir: {}
  {{- with $provisioner.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $provisioner.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $provisioner.tolerations }}
  tolerations:
    {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}

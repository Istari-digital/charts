{{/*
The provisioning Job's full pod template (`metadata` + `spec`), rendered identically for the Job
manifest and the Job's name hash. Everything here must be deterministic -- no `.Release.Revision`,
timestamps, random values, or chart-version labels (see `provisioner.podLabels`) -- because the Job
name hashes this block to rerun on change (mechanism and immutability rationale in job.yaml).
*/}}
{{- define "provisioner.podTemplate" -}}
{{- $provisioner := .Values.provisioner }}
{{/*
The image emits only generated credential material, so the chart passes just the Secret names,
namespace, labels, and ServiceAccount name. The identity config the services need (redirect URIs,
authority URL, enable flags) comes from their own ConfigMaps, not the provisioner.
*/}}
{{- $tfVars := list
  (dict "name" "TF_VAR_common_labels" "value" (include "provisioner.podLabels" . | fromYaml | toJson))
  (dict "name" "TF_VAR_identity_platform_clients_secret_name" "value" (include "provisioner.identityPlatformClientsSecretName" .))
  (dict "name" "TF_VAR_mcp_secret_name" "value" (include "provisioner.mcpSecretName" .))
  (dict "name" "TF_VAR_namespace" "value" .Release.Namespace)
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

{{/*
Shared pod spec for the dgraph-sec validator, used by the `helm test` Pod, the
post-install hook Job, and the suspended manual CronJob. Emits the body of a pod
`spec:` at column 0; each caller includes it with `nindent` for its nesting.

Transport mirrors the ACL bootstrap reconciler: under native TLS (no service
mesh) the validator targets the alpha-0 headless FQDN (a cert SAN) over HTTPS
with the chart CA and optional client cert; inside a mesh it talks plaintext to
the ClusterIP Service and the sidecar handles encryption. The validator keeps
its sidecar (no sidecar.istio.io/inject=false): native Kubernetes sidecars
terminate when the validator container exits, so the Job/test still completes,
and a sidecar-less pod cannot reach Alpha under a STRICT-mTLS mesh.
*/}}
{{- define "dgraph-sec.validation.podSpec" -}}
{{- $nativeTLS := eq (include "dgraph-sec.nativeTLS" (dict "ctx" . "tls" .Values.alpha.tls)) "true" -}}
{{- $credsSecret := .Values.alpha.acl.bootstrap.existingSecret | default .Values.alpha.acl.existingSecret | default (printf "%s-acl-secret" (include "dgraph-sec.alpha.fullname" .)) -}}
restartPolicy: Never
{{- include "dgraph-sec.imagePullSecrets" . | nindent 0 }}
{{- if .Values.validation.rbac.enabled }}
serviceAccountName: {{ include "dgraph-sec.alpha.fullname" . }}-validate
{{- else }}
automountServiceAccountToken: false
{{- end }}
{{- $nodeSelector := .Values.validation.nodeSelector | default .Values.alpha.nodeSelector }}
{{- with $nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- $tolerations := .Values.validation.tolerations | default .Values.alpha.tolerations }}
{{- with $tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.alpha.securityContext.enabled }}
securityContext:
{{- omit .Values.alpha.securityContext "enabled" | toYaml | nindent 2 }}
{{- end }}
containers:
- name: validate
{{- /* Use the override only when registry, repository, and tag are all set; a
       partial override would render an invalid image reference, so fall back to
       the shared dgraph-sec image instead. */}}
{{- if and .Values.validation.image .Values.validation.image.registry .Values.validation.image.repository .Values.validation.image.tag }}
  image: {{ printf "%s/%s:%s" .Values.validation.image.registry .Values.validation.image.repository (.Values.validation.image.tag | toString) }}
{{- else }}
  image: {{ include "dgraph-sec.image" . }}
{{- end }}
  imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
{{- if .Values.alpha.containerSecurityContext.enabled }}
  securityContext:
{{- omit .Values.alpha.containerSecurityContext "enabled" | toYaml | nindent 4 }}
{{- end }}
  command: ["/usr/bin/bash", "/scripts/validate.sh"]
  env:
  - name: ALPHA_HOST
{{- if $nativeTLS }}
    value: {{ printf "%s-0.%s-headless.%s.svc%s" (include "dgraph-sec.alpha.fullname" .) (include "dgraph-sec.alpha.fullname" .) (include "dgraph-sec.namespace" .) (include "dgraph-sec.domainSuffix" .) | quote }}
{{- else }}
    value: {{ include "dgraph-sec.alpha.fullname" . | quote }}
{{- end }}
  - name: EXPECTED_JSON
    value: /config/expected.json
  - name: CREDS_DIR
    value: /creds
  - name: RETRIES
    value: {{ .Values.validation.retries | quote }}
  - name: RETRY_SLEEP
    value: {{ .Values.validation.retrySleep | quote }}
{{- if $nativeTLS }}
  - name: CACERT_PATH
    value: /dgraph/tls/ca.crt
{{- if .Values.alpha.tls.clientName }}
  - name: CLIENT_CERT_PATH
    value: /dgraph/tls/client.{{ .Values.alpha.tls.clientName }}.crt
  - name: CLIENT_KEY_PATH
    value: /dgraph/tls/client.{{ .Values.alpha.tls.clientName }}.key
{{- end }}
{{- end }}
  volumeMounts:
  - name: scripts
    mountPath: /scripts
  - name: config
    mountPath: /config
{{- if .Values.alpha.acl.enabled }}
  - name: creds
    mountPath: /creds
    readOnly: true
{{- end }}
{{- if $nativeTLS }}
  - name: tls-volume
    mountPath: /dgraph/tls
    readOnly: true
{{- end }}
volumes:
- name: scripts
  configMap:
    name: {{ include "dgraph-sec.alpha.fullname" . }}-validate
    defaultMode: 0555
    items:
    - key: validate.sh
      path: validate.sh
- name: config
  secret:
    secretName: {{ include "dgraph-sec.alpha.fullname" . }}-validate
    items:
    - key: expected.json
      path: expected.json
{{- if .Values.alpha.acl.enabled }}
- name: creds
  secret:
    secretName: {{ $credsSecret }}
{{- end }}
{{- if $nativeTLS }}
- name: tls-volume
  secret:
    secretName: {{ include "dgraph-sec.alpha.fullname" . }}-tls-secret
{{- end }}
{{- end -}}

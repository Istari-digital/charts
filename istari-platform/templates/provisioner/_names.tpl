{{/*
Name/prefix for provisioner resources (ServiceAccount/Role/RoleBinding/Job), and the base the
generated Secret names below derive from. Honours fullnameOverride, otherwise release-scoped.
*/}}
{{- define "provisioner.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
The provisioning Job's name is built in job.yaml, not here: it appends a hash of the Job's pod
template to this prefix so a changed input renames the Job (see provisioner/_helpers.tpl).
*/}}

{{/*
Generated-credential Secret names.

Each derives from `provisioner.fullname`, so a single release that installs the provisioner and its
consumers together agrees on the names with no configuration, and a consumer in a separate release
(`provisioner.external`) agrees by sharing the same `fullnameOverride`/release name. Two releases in
one namespace collide on these names -- as on every other chart-named resource -- unless given
distinct `fullnameOverride` values, since `fullnameOverride` defaults to `istari` and takes
precedence over the release name.
*/}}

{{/*
Secret carrying registry's private credential blob.
*/}}
{{- define "provisioner.registrySecretName" -}}
{{- printf "%s-registry-credentials" (include "provisioner.fullname" .) -}}
{{- end }}

{{/*
Secret carrying mcp's placeholder client_secret.
*/}}
{{- define "provisioner.mcpSecretName" -}}
{{- printf "%s-mcp-credentials" (include "provisioner.fullname" .) -}}
{{- end }}

{{/*
Secret carrying the env vars identity-service reads at startup to self-register
registry/frontend/mcp.
*/}}
{{- define "provisioner.identityPlatformClientsSecretName" -}}
{{- printf "%s-identity-platform-clients" (include "provisioner.fullname" .) -}}
{{- end }}

{{/*
Suffix for the Terraform kubernetes backend's state Secret / lock Lease. Defaults to a name
derived from `provisioner.fullname` so separate releases keep separate state; override to pin it.
The backend reserves a trailing `-<number>` for its own state-chunking index, so an override ending
in one would collide with those chunk names and yield unreadable state -- rejected at render time.
*/}}
{{- define "provisioner.stateSecretSuffix" -}}
{{- if .Values.provisioner.backend.secretSuffix -}}
{{- if regexMatch "-[0-9]+$" .Values.provisioner.backend.secretSuffix -}}
{{- fail (printf "provisioner.backend.secretSuffix (%q) must not end in -<number>: the Terraform kubernetes backend reserves that suffix shape for its own state-chunking index, so such a value produces colliding, unreadable state Secret names" .Values.provisioner.backend.secretSuffix) -}}
{{- end -}}
{{- .Values.provisioner.backend.secretSuffix -}}
{{- else -}}
{{- printf "%s-terraform-state" (include "provisioner.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
The kubernetes backend's state Secret name: `tfstate-<workspace>-<suffix>`. This release never
selects a Terraform workspace, so the workspace segment is always `default`.
*/}}
{{- define "provisioner.stateSecretName" -}}
{{- printf "tfstate-default-%s" (include "provisioner.stateSecretSuffix" .) -}}
{{- end }}

{{/*
The kubernetes backend's lock Lease name: `lock-<stateSecretName>`.
*/}}
{{- define "provisioner.stateLockLeaseName" -}}
{{- printf "lock-%s" (include "provisioner.stateSecretName" .) -}}
{{- end }}

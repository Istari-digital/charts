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
The provisioning Job's name is built in job.yaml, not here: it appends a hash of the Job's inputs
to this prefix so a changed input renames the Job (see provisioner/_helpers.tpl and job.yaml).
*/}}

{{/*
Generated-credential Secret names.

Each derives from `provisioner.fullname`, so a single release that installs the provisioner and its
consumers together agrees on the names with no configuration, and a consumer in a separate release
(`provisioner.external`) agrees by sharing the same `fullnameOverride` -- two releases in one
namespace can't share a release name, so the override is the only cross-release handle. Two releases in
one namespace collide on these names -- as on every other chart-named resource -- unless given
distinct `fullnameOverride` values, since `fullnameOverride` defaults to `istari` and takes
precedence over the release name.
*/}}

{{/*
One generated Secret name: `<provisioner.fullname>-<base>`, plus `-<iteration>` once
`provisioner.secretRotationIteration` leaves its default. Renaming the Secrets on rotation is what
makes the consumers' new pods wait for the provisioner to write the new material instead of
restarting onto the old. Input: dict with `root` (the chart context), `base`, and `iteration`.
*/}}
{{- define "provisioner.generatedSecretName" -}}
{{- $iteration := int .iteration -}}
{{- printf "%s-%s%s" (include "provisioner.fullname" .root) .base (ternary "" (printf "-%d" $iteration) (eq $iteration 1)) -}}
{{- end }}

{{/*
Secret carrying registry's private credential blob.
*/}}
{{- define "provisioner.registrySecretName" -}}
{{- include "provisioner.generatedSecretName" (dict "root" . "base" "registry-credentials" "iteration" .Values.provisioner.secretRotationIteration) -}}
{{- end }}

{{/*
Secret carrying mcp's placeholder client_secret.
*/}}
{{- define "provisioner.mcpSecretName" -}}
{{- include "provisioner.generatedSecretName" (dict "root" . "base" "mcp-credentials" "iteration" .Values.provisioner.secretRotationIteration) -}}
{{- end }}

{{/*
Secret carrying the env vars identity-service reads at startup to self-register
registry/frontend/mcp.
*/}}
{{- define "provisioner.identityPlatformClientsSecretName" -}}
{{- include "provisioner.generatedSecretName" (dict "root" . "base" "identity-platform-clients" "iteration" .Values.provisioner.secretRotationIteration) -}}
{{- end }}

{{/*
Secret carrying identity-service's own generated keys: its token signing key and token encryption
key.
*/}}
{{- define "provisioner.identitySecretName" -}}
{{- include "provisioner.generatedSecretName" (dict "root" . "base" "identity-keys" "iteration" .Values.provisioner.secretRotationIteration) -}}
{{- end }}

{{/*
Every generated Secret name from iteration 1 up to the current one, as YAML list items for the
Role's resourceNames: a rotation still has Terraform read and delete the previous iteration's
Secrets, so the provisioner keeps name-scoped access to them.
*/}}
{{- define "provisioner.generatedSecretNames" -}}
{{- $root := . -}}
{{- range $iteration := untilStep 1 (int (add1 (int .Values.provisioner.secretRotationIteration))) 1 }}
{{- range $base := list "registry-credentials" "mcp-credentials" "identity-platform-clients" "identity-keys" }}
- {{ include "provisioner.generatedSecretName" (dict "root" $root "base" $base "iteration" $iteration) | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Suffix for the Terraform kubernetes backend's state Secret / lock Lease, derived from
`provisioner.fullname`; override to pin it. Because `fullnameOverride` defaults to `istari`,
separate releases share this state unless given distinct `fullnameOverride` values.
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

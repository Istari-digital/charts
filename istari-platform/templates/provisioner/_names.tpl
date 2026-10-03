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

Each defaults to a name derived from `provisioner.fullname`, so a single release that installs the
provisioner and its consumers together agrees on the names with no configuration, and two releases
in one namespace get distinct names instead of colliding. Each can be pinned with an explicit
override: set the matching override on every release involved when the provisioner runs in a
separate release from a consumer (`provisioner.external`), so the two agree on the name.
*/}}

{{/*
Secret carrying registry's private credential blob.
*/}}
{{- define "provisioner.registrySecretName" -}}
{{- if .Values.provisioner.clients.registry.secretName -}}
{{- .Values.provisioner.clients.registry.secretName -}}
{{- else -}}
{{- printf "%s-registry-credentials" (include "provisioner.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Secret carrying frontend's client_id.
*/}}
{{- define "provisioner.frontendSecretName" -}}
{{- if .Values.provisioner.clients.frontend.secretName -}}
{{- .Values.provisioner.clients.frontend.secretName -}}
{{- else -}}
{{- printf "%s-frontend-credentials" (include "provisioner.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Secret carrying mcp's client_id + placeholder client_secret.
*/}}
{{- define "provisioner.mcpSecretName" -}}
{{- if .Values.provisioner.clients.mcp.secretName -}}
{{- .Values.provisioner.clients.mcp.secretName -}}
{{- else -}}
{{- printf "%s-mcp-credentials" (include "provisioner.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Secret carrying the env vars identity-service reads at startup to self-register
registry/frontend/mcp.
*/}}
{{- define "provisioner.identityPlatformClientsSecretName" -}}
{{- if .Values.provisioner.identityPlatformClientsSecretName -}}
{{- .Values.provisioner.identityPlatformClientsSecretName -}}
{{- else -}}
{{- printf "%s-identity-platform-clients" (include "provisioner.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Suffix for the Terraform kubernetes backend's state Secret / lock Lease. Defaults to a name
derived from `provisioner.fullname` so separate releases keep separate state; override to pin it.
The backend reserves a trailing `-<number>` for its own state-chunking index, so an override must
not end in one.
*/}}
{{- define "provisioner.stateSecretSuffix" -}}
{{- if .Values.provisioner.backend.secretSuffix -}}
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

{{/*
Default name/prefix for provisioner resources (ServiceAccount/Role/RoleBinding/Job/terraform-files
Secret -- all release-scoped, unlike the output-credential Secrets below).
*/}}
{{- define "provisioner.fullname" -}}
    {{- /* trunc 33, not 63: bounded so the longest suffix appended below (-terraform-files, 16
           chars) never gets truncated away -- 63-16=47 would technically be tight enough, but 33
           matches the same conservative bound reserved for the (now-static) output Secret names
           this helper used to feed, kept here rather than re-tuned per suffix. */ -}}
    {{- if .Values.fullnameOverride }}
        {{- printf "%s-%s" .Values.fullnameOverride "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- else }}
        {{- printf "%s-%s" .Release.Name "provisioner" | trunc 33 | trimSuffix "-" | replace "_" "-" }}
    {{- end }}
{{- end }}

{{/*
Secret carrying the packaged .tf files + rendered terraform.tfvars.
*/}}
{{- define "provisioner.terraformFilesSecretName" -}}
{{ printf "%s-terraform-files" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The one-shot provisioning Job name.
*/}}
{{- define "provisioner.jobName" -}}
{{ printf "%s-apply" (include "provisioner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Output-credential Secret names below are deliberately STATIC literals, not derived from
.fullname/.Release.Name -- provisioner is meant to be a namespace-singleton (like
istari-zitadel-configurator's own static "zitadel-*-env" Secret names), and a consuming release
(one-release-per-service topology) computes these same helpers from ITS OWN .Release.Name. A
release-relative name would make the producer and consumer releases derive different Secret
names for the same credential, which is exactly the bug this fixes.
*/}}

{{/*
Secret carrying registry's private credential blob. Listed in fileservice.extraEnvSecrets.
*/}}
{{- define "provisioner.registrySecretName" -}}
istari-provisioner-registry-credentials
{{- end }}

{{/*
Secret carrying frontend's client_id.
*/}}
{{- define "provisioner.frontendSecretName" -}}
istari-provisioner-frontend-credentials
{{- end }}

{{/*
Secret carrying mcp's client_id + placeholder client_secret.
*/}}
{{- define "provisioner.mcpSecretName" -}}
istari-provisioner-mcp-credentials
{{- end }}

{{/*
Secret carrying serviceClients.yaml — what identity's provision-service-clients Job mounts.
*/}}
{{- define "provisioner.serviceClientsSecretName" -}}
istari-provisioner-service-clients
{{- end }}

{{/*
Secret carrying the settings identity-service registers the registry, frontend and mcp clients
from at startup. Listed in identity's extraEnvSecrets.
*/}}
{{- define "provisioner.identityPlatformClientsSecretName" -}}
istari-provisioner-identity-platform-clients
{{- end }}

{{/*
Whether identity-service's platform-clients Secret is written: the registry, frontend or mcp
client is enabled. Returns "true" or "".
*/}}
{{- define "provisioner.identityPlatformClientsEnabled" -}}
{{- if or (include "provisioner.clientEnabled" (list . "registry")) (include "provisioner.clientEnabled" (list . "frontend")) (include "provisioner.clientEnabled" (list . "mcp")) -}}
true
{{- end -}}
{{- end }}

{{/*
Whether at least one client is enabled. Returns "true" or "".
*/}}
{{- define "provisioner.anyClientEnabled" -}}
{{- if or (include "provisioner.clientEnabled" (list . "registry")) (include "provisioner.clientEnabled" (list . "frontend")) (include "provisioner.clientEnabled" (list . "mcp")) -}}
true
{{- end -}}
{{- end }}

{{/*
Whether this release runs the provisioner: as written, or, unset, where it deploys identity-service.
*/}}
{{- define "provisioner.enabled" -}}
{{- $v := dig "enabled" nil .Values.provisioner -}}
{{- if kindIs "bool" $v -}}
{{- if $v }}true{{ end -}}
{{- else if include "istari-platform.identityEnabled" . -}}
true
{{- end -}}
{{- end }}

{{/*
One client's enabled value as written, or, unset, whether clients use identity-service; call with (list $ "<client>").
*/}}
{{- define "provisioner.clientEnabled" -}}
{{- $root := index . 0 -}}
{{- $v := dig (index . 1) "enabled" nil (default dict $root.Values.provisioner.clients) -}}
{{- if kindIs "bool" $v -}}
{{- if $v }}true{{ end -}}
{{- else if eq (include "istari-platform.identityClientIntegration" $root) "true" -}}
true
{{- end -}}
{{- end }}

{{/*
Whether the bootstrap roles Job has a registry client id: set directly, in another Secret, or written by this provisioner.
*/}}
{{- define "identity.bootstrap.registryClientIdResolves" -}}
{{- $b := .Values.identity.bootstrap -}}
{{- $ref := default dict $b.registryClientIdSecretRef -}}
{{- if $b.registryClientId -}}
true
{{- else if and $ref.name (ne $ref.name (include "provisioner.registrySecretName" .)) -}}
true
{{- else if and $ref.name (include "provisioner.clientEnabled" (list . "registry")) -}}
true
{{- end -}}
{{- end }}

{{/*
A service's own env Secrets (secretName, then extraEnvSecrets), minus the provisioner's; call with (list $ <service values>). Returns a JSON list.
*/}}
{{- define "provisioner.serviceEnvSecretNames" -}}
{{- $root := index . 0 -}}
{{- $svc := index . 1 -}}
{{- $own := list (include "provisioner.registrySecretName" $root) (include "provisioner.frontendSecretName" $root) (include "provisioner.mcpSecretName" $root) (include "provisioner.identityPlatformClientsSecretName" $root) -}}
{{- $names := list -}}
{{- range concat (compact (list $svc.secretName)) ($svc.extraEnvSecrets | default list) -}}
{{- if and . (not (has . $own)) (not (has . $names)) -}}
{{- $names = append $names . -}}
{{- end -}}
{{- end -}}
{{- toJson $names -}}
{{- end }}

{{/*
Adopt sources for one client as an HCL list: each service's own Secrets under its keys, then
provisioner.adopt's entries; call with (list $ (list (list <service values> <keys>) ...) <adopt entries>).
*/}}
{{- define "provisioner.adoptSources" -}}
{{- $root := index . 0 -}}
{{- $sources := list -}}
{{- range index . 1 -}}
{{- $keys := index . 1 -}}
{{- range include "provisioner.serviceEnvSecretNames" (list $root (index . 0)) | fromJsonArray -}}
{{- $name := . -}}
{{- range $keys -}}
{{- $sources = append $sources (dict "secretName" $name "key" .) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $sources = concat $sources (index . 2 | default list) | uniq -}}
[{{- range $i, $s := $sources }}{{ if $i }}, {{ end }}{ name = {{ $s.secretName | quote }}, key = {{ $s.key | quote }} }{{- end }}]
{{- end }}

{{/*
Redirect URIs for the hosts this release serves a workload at, from its Ingress and VirtualService,
as an HCL list; call with (list <service values> <path>). VirtualService short names are skipped.
*/}}
{{- define "provisioner.hostRedirectUris" -}}
{{- $svc := index . 0 -}}
{{- $path := index . 1 -}}
{{- $uris := list -}}
{{- if $svc.enabled -}}
{{- if $svc.ingress.enabled -}}
{{- range $svc.ingress.hosts -}}
{{- if .host -}}{{- $uris = append $uris (printf "https://%s%s" .host $path) -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- if $svc.virtualService.enabled -}}
{{- range $svc.virtualService.hosts -}}
{{- if contains "." . -}}{{- $uris = append $uris (printf "https://%s%s" . $path) -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
[{{- range $i, $u := uniq $uris }}{{ if $i }}, {{ end }}{{ $u | quote }}{{- end }}]
{{- end }}

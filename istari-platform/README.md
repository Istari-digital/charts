# istari-platform

![Version: 3.23.0](https://img.shields.io/badge/Version-3.23.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 10.x.x](https://img.shields.io/badge/AppVersion-10.x.x-informational?style=flat-square)

An umbrella helm chart used to install all Kubernetes components of the Istari Digital Platform's control plane.

## Installation

>[!NOTE]
>Pulling the chart requires access to Istari Digital's Artifactory.
>Please contact the [Support Team](mailto:support@istaridigital.com) for more information.

Instructions for installing the istari-platform chart are available in the IT Admins section of the [official Istari Documentation](https://docs.istaridigital.com/).

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://istaridigital.jfrog.io/artifactory/main-helm-local | dgraph-sec | 0.6.1 |
| https://jaegertracing.github.io/helm-charts | jaeger | 4.11.1 |
| https://nats-io.github.io/k8s/helm/charts/ | nats | 2.14.0 |

> [!NOTE]
> The `nats`, `jaeger`, and `dgraph-sec` dependencies are **optional** (`nats.enabled` / `jaeger.enabled` / `dgraph-sec.enabled`, default `false`). Disabled subcharts are not rendered at install time. See the corresponding blocks under [Values](#values).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonLabels | object | `{}` | Additional labels to add to all resources of all services |
| dgraph-sec.alpha.acl.bootstrap.enabled | bool | `false` | Run the ACL bootstrap/reconciler Job. |
| dgraph-sec.alpha.acl.bootstrap.existingSecret | string | `""` | Secret holding groot and user passwords for the bootstrap Job. |
| dgraph-sec.alpha.acl.bootstrap.grootPasswordSecretKey | string | `"groot_password"` | Key in the Secret holding groot's rotated password. |
| dgraph-sec.alpha.acl.bootstrap.groups | list | `[]` | ACL groups to ensure, with predicate rules. |
| dgraph-sec.alpha.acl.bootstrap.rotation | string | `""` | Opaque rotation token to force re-running the reconciler on upgrade. |
| dgraph-sec.alpha.acl.bootstrap.users | list | `[]` |  |
| dgraph-sec.alpha.acl.enabled | bool | `false` | Enable Dgraph ACL on alpha (--acl secret-file=…). |
| dgraph-sec.alpha.acl.existingSecret | string | `""` | Pre-created Secret holding the HMAC; empty means the chart creates one from `file`. |
| dgraph-sec.alpha.acl.secretFile | string | `"hmac_secret_file"` | Filename/key of the HMAC secret mounted at /dgraph/acl/<secretFile>. |
| dgraph-sec.alpha.antiAffinity | string | `"hard"` |  |
| dgraph-sec.alpha.extraEnvs[0].name | string | `"GOGC"` |  |
| dgraph-sec.alpha.extraEnvs[0].value | string | `"50"` |  |
| dgraph-sec.alpha.extraEnvs[1].name | string | `"GOMEMLIMIT"` |  |
| dgraph-sec.alpha.extraEnvs[1].value | string | `"8GiB"` |  |
| dgraph-sec.alpha.extraFlags | string | `"--cache \"size-mb=4096; percentage=40,40,20;\""` |  |
| dgraph-sec.alpha.logLevel | string | `"normal"` |  |
| dgraph-sec.alpha.nodeSelector | object | `{}` | Node selector for alpha pod scheduling. |
| dgraph-sec.alpha.persistence.enabled | bool | `false` | Enable persistent storage for alpha data. |
| dgraph-sec.alpha.replicaCount | int | `3` |  |
| dgraph-sec.alpha.resources.limits.memory | string | `"10Gi"` |  |
| dgraph-sec.alpha.resources.requests.cpu | string | `"2000m"` |  |
| dgraph-sec.alpha.resources.requests.memory | string | `"10Gi"` |  |
| dgraph-sec.alpha.tolerations | list | `[]` | Tolerations for alpha pod scheduling. |
| dgraph-sec.backups.full.enabled | bool | `true` |  |
| dgraph-sec.backups.full.schedule | string | `"0 0 * * *"` |  |
| dgraph-sec.backups.incremental.enabled | bool | `true` |  |
| dgraph-sec.backups.incremental.schedule | string | `"0 1-23 * * *"` |  |
| dgraph-sec.enabled | bool | `false` | Enable / Disable the dgraph-sec subchart. When `false`, the subchart is not rendered at all. |
| dgraph-sec.fullnameOverride | string | `"dgraph-sec"` | Override the resource name prefix. Production uses `dgraph-sec` so Services are `dgraph-sec-alpha`, etc. |
| dgraph-sec.image.registry | string | `"istaridigital.jfrog.io"` |  |
| dgraph-sec.image.repository | string | `"main-docker-local/dgraph-sec"` |  |
| dgraph-sec.image.tag | string | `"v25.3.7-sec.0.2.2"` |  |
| dgraph-sec.imagePullSecrets[0].name | string | `"docker-pull-secret"` |  |
| dgraph-sec.preUpgradeHook.enabled | bool | `false` |  |
| dgraph-sec.ratel.enabled | bool | `false` |  |
| dgraph-sec.zero.antiAffinity | string | `"hard"` |  |
| dgraph-sec.zero.logLevel | string | `"normal"` |  |
| dgraph-sec.zero.nodeSelector | object | `{}` | Node selector for zero pod scheduling. |
| dgraph-sec.zero.persistence.enabled | bool | `false` | Enable persistent storage for zero data. |
| dgraph-sec.zero.replicaCount | int | `3` |  |
| dgraph-sec.zero.resources.limits.memory | string | `"2Gi"` |  |
| dgraph-sec.zero.resources.requests.cpu | string | `"500m"` |  |
| dgraph-sec.zero.resources.requests.memory | string | `"2Gi"` |  |
| dgraph-sec.zero.shardReplicaCount | int | `3` |  |
| dgraph-sec.zero.tolerations | list | `[]` | Tolerations for zero pod scheduling. |
| docs.affinity | object | `{}` | Affinity |
| docs.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| docs.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| docs.autoscaling.maxReplicas | int | `2` | Maximum number of replicas |
| docs.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| docs.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| docs.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| docs.containerSecurityContext | object | `{"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":1000}` | Primary container's security context |
| docs.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| docs.enabled | bool | `false` | Enable / Disable the whole deployment |
| docs.env | list | `[]` |  |
| docs.image | string | `"docs-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| docs.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| docs.ingress.annotations | object | `{}` | Annotations on the Ingress. Use this for controller-specific behavior (cert-manager, nginx, ALB, etc.). |
| docs.ingress.className | string | `""` | `ingressClassName` on the Ingress. Leave empty to use the cluster's default IngressClass. |
| docs.ingress.enabled | bool | `false` | Create a Kubernetes Ingress for this service. The cluster must have an Ingress controller (nginx, ALB / EKS Auto Mode, GCE, Traefik, etc.) that watches the chosen IngressClass. |
| docs.ingress.hosts | list | `[{"host":"docs.istari.customer-domain.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | One entry per `spec.rules[]`. `host` is optional — when omitted, the rule matches any host. |
| docs.ingress.labels | object | `{}` | Additional labels on the Ingress (in addition to the standard docs labels). |
| docs.ingress.servicePort | int | `80` | Service port the Ingress targets. Defaults to 80. |
| docs.ingress.tls | list | `[]` | TLS configuration; passed through to `spec.tls[]` verbatim. |
| docs.nodeSelector | object | `{}` | Node selector |
| docs.podAnnotations | object | `{}` | Additional annotations to add to pods |
| docs.podLabels | object | `{}` | Additional labels to add to pods |
| docs.podSecurityContext | object | `{"fsGroup":2000}` | Pod security context |
| docs.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| docs.replicaCount | int | `1` | Replica count |
| docs.resources | object | `{}` |  |
| docs.restartPolicy | string | `"Always"` | Restart policy |
| docs.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| docs.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| docs.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| docs.tag | string | `"6.14.0"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| docs.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| docs.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| docs.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| docs.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| docs.virtualService.hosts | list | `["docs.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| docs.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard docs labels). |
| docs.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| docs.volumes | list | `[]` | Pod Volumes |
| fileservice.affinity | object | `{}` | Affinity |
| fileservice.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| fileservice.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| fileservice.autoscaling.maxReplicas | int | `2` | Maximum number of replicas |
| fileservice.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| fileservice.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| fileservice.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| fileservice.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":65532}` | Primary container's security context |
| fileservice.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| fileservice.enabled | bool | `true` | Enable / Disable the whole deployment |
| fileservice.env | list | `[]` |  |
| fileservice.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| fileservice.image | string | `"fileservice2"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| fileservice.ingress.annotations | object | `{}` | Annotations on the Ingress. Use this for controller-specific behavior (cert-manager, nginx, ALB, etc.). |
| fileservice.ingress.className | string | `""` | `ingressClassName` on the Ingress. Leave empty to use the cluster's default IngressClass. |
| fileservice.ingress.enabled | bool | `false` | Create a Kubernetes Ingress for this service. The cluster must have an Ingress controller (nginx, ALB / EKS Auto Mode, GCE, Traefik, etc.) that watches the chosen IngressClass. |
| fileservice.ingress.hosts | list | `[{"host":"registry.istari.customer-domain.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | One entry per `spec.rules[]`. `host` is optional — when omitted, the rule matches any host. |
| fileservice.ingress.labels | object | `{}` | Additional labels on the Ingress (in addition to the standard fileservice labels). |
| fileservice.ingress.servicePort | int | `80` | Service port the Ingress targets. Defaults to 80. |
| fileservice.ingress.tls | list | `[]` | TLS configuration; passed through to `spec.tls[]` verbatim. |
| fileservice.migrations.autoCleanupSuccessfulJob | bool | `true` | Automatically clean up the successful migration hook `Job` by including **`hook-succeeded`** in `helm.sh/hook-delete-policy` (alongside `before-hook-creation`). When `true`, Helm may remove the Job after the migration succeeds (less clutter; logs are shorter-lived on the cluster). When `false`, only `before-hook-creation` is set, so the completed Job (and its Pods) remain until the next install or upgrade replaces the hook—useful for auditing or inspecting migration logs. |
| fileservice.migrations.backoffLimit | int | `0` | `spec.backoffLimit` for the migration `Job` (number of retries after a failed Pod). `0` means no retries. |
| fileservice.migrations.podAnnotations | object | `{}` | Annotations for the migration Job Pod template only (e.g. `sidecar.istio.io/inject: "false"` to disable Istio sidecar injection). |
| fileservice.migrations.podLabels | object | `{}` | Extra labels for the migration Job Pod template only (in addition to the standard fileservice labels). |
| fileservice.migrations.runAsJob | bool | `false` | Run Alembic database migrations as a Helm `pre-install` / `pre-upgrade` Job instead of a Deployment `initContainer`. When `true`, a `Job` runs `alembic upgrade head` once per release before the fileservice Deployment rolls out; the fileservice `ServiceAccount` is annotated with the same hooks so it exists before the Job runs. When `false`, migrations run in an `initContainer` on each fileservice Pod before the main container starts (legacy behavior). |
| fileservice.nodeSelector | object | `{}` | Node selector |
| fileservice.podAnnotations | object | `{}` | Additional annotations to add to pods |
| fileservice.podLabels | object | `{}` | Additional labels to add to pods |
| fileservice.podSecurityContext | object | `{"fsGroup":65532}` | Pod security context |
| fileservice.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.replicaCount | int | `1` | Replica count |
| fileservice.resources | object | `{}` |  |
| fileservice.restartPolicy | string | `"Always"` | Restart policy |
| fileservice.secretName | string | `"istari-fileservice"` | Secret name. The secret should contain the environment variables required by the service. |
| fileservice.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| fileservice.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| fileservice.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| fileservice.tag | string | `"10.21.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| fileservice.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| fileservice.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| fileservice.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| fileservice.virtualService.hosts | list | `["registry.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| fileservice.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard fileservice labels). |
| fileservice.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| fileservice.volumes | list | `[]` | Pod Volumes |
| frontend.affinity | object | `{}` | Affinity |
| frontend.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| frontend.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| frontend.autoscaling.maxReplicas | int | `3` | Maximum number of replicas |
| frontend.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| frontend.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| frontend.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| frontend.containerSecurityContext | object | `{"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":65532}` | Primary container's security context |
| frontend.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| frontend.enabled | bool | `true` | Enable / Disable the whole deployment |
| frontend.env | list | `[]` |  |
| frontend.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| frontend.image | string | `"frontend-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| frontend.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| frontend.ingress.annotations | object | `{}` | Annotations on the Ingress. Use this for controller-specific behavior: cert-manager (`cert-manager.io/cluster-issuer`), nginx (`nginx.ingress.kubernetes.io/*`), ALB (`alb.ingress.kubernetes.io/scheme`, `target-type`, `certificate-arn`, `group.name`, `group.order`), etc. |
| frontend.ingress.className | string | `""` | `ingressClassName` on the Ingress. Leave empty to use the cluster's default IngressClass (the one annotated `ingressclass.kubernetes.io/is-default-class: "true"`). |
| frontend.ingress.enabled | bool | `false` | Create a Kubernetes Ingress for this service. The cluster must have an Ingress controller (nginx, ALB / EKS Auto Mode, GCE, Traefik, etc.) that watches the chosen IngressClass. |
| frontend.ingress.hosts | list | `[{"host":"istari.customer-domain.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | One entry per `spec.rules[]`. `host` is optional — when omitted, the rule matches any host (per the Kubernetes Ingress API and the EKS Auto Mode ALB example). |
| frontend.ingress.labels | object | `{}` | Additional labels on the Ingress (in addition to the standard frontend labels). |
| frontend.ingress.servicePort | int | `80` | Service port the Ingress targets. Defaults to 80, the port every service in this chart exposes. |
| frontend.ingress.tls | list | `[]` | TLS configuration; passed through to `spec.tls[]` verbatim. Secrets must exist (or be created via cert-manager annotations). |
| frontend.nodeSelector | object | `{}` | Node selector |
| frontend.podAnnotations | object | `{}` | Additional annotations to add to pods |
| frontend.podLabels | object | `{}` | Additional labels to add to pods |
| frontend.podSecurityContext | object | `{"fsGroup":65532}` | Pod security context |
| frontend.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| frontend.replicaCount | int | `1` | Replica count |
| frontend.resources | object | `{}` |  |
| frontend.restartPolicy | string | `"Always"` | Restart policy |
| frontend.secretName | string | `"istari-frontend"` | Secret name. The secret should contain the environment variables required by the service. |
| frontend.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| frontend.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| frontend.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| frontend.tag | string | `"8.34.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| frontend.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| frontend.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| frontend.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| frontend.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| frontend.virtualService.hosts | list | `["istari.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| frontend.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard frontend labels). |
| frontend.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| frontend.volumes | list | `[]` | Pod Volumes |
| fullnameOverride | string | `"istari"` | Override the prefix used for resource names, which defaults to the chart name (istari-platform). |
| identityService.affinity | object | `{}` | Affinity |
| identityService.agentRegistration | object | (see fields below) | Settings for the agent-registration one-shot hook Jobs (pre-install/pre-upgrade). For each entry in `agents`, one Job runs `create-tenant` (idempotent, as an init container) and then `register-agent`, provisioning a service principal's tenant and public key in the identity-service. Used to onboard autonomous service agents that authenticate to the identity-service via `client_credentials` (e.g. the secure-connection-service, DPLAT-513). Rendered only when BOTH `identityService.enabled` and `identityService.agentRegistration.enabled` are `true` AND `agents` is non-empty. Each agent's inputs (its public-only credential blob, the DB URL, and — for upstream binding — its username / org id) are supplied as env vars via `envFrom` on `identityService.secretName` plus `agentRegistration.extraEnvSecrets`, and the CLIs read them by name; the identity-service never needs read access to another service's secret and is never handed private key material. The Job pods inherit the identity-service's `nodeSelector`, `affinity`, `tolerations`, security contexts, and image-pull secrets; only `podAnnotations`, `podLabels`, and `resources` are configured separately here. |
| identityService.agentRegistration.agents | list | `[]` | Agents to provision, one Job each. All inputs are read from env vars supplied via `envFrom` (`identityService.secretName` + `agentRegistration.extraEnvSecrets`); the fields below name those env vars. Fields per entry: `name` (required; used to build the Job name — letters, digits, hyphens, and underscores only); `tenantSlug` (required, identity-service tenant the agent belongs to); `keyEnv` (required, the env var holding the base64-encoded public-only agent credential blob); `tenantDisplayName` (optional human-readable tenant name); `providerName` + `providerTenantIdEnv` (optional, supplied together; `providerName` is the upstream IdP name e.g. `zitadel` and `providerTenantIdEnv` names the env var holding the upstream org id — maps the tenant to the upstream org so the agent's token carries the resourceowner for Zitadel-namespaced role lookups); `usernameEnv` (optional, names the env var holding the upstream user id — binds the agent to a pre-existing IdP identity, e.g. the secure-connection-service's `rss_service_user` grant); `displayName` (optional agent name claim). An env var that is absent/empty makes the CLI skip that piece (register-agent no-ops; create-tenant skips the mapping). |
| identityService.agentRegistration.autoCleanupSuccessfulJob | bool | `true` | Automatically clean up successful registration hook `Job`s by including **`hook-succeeded`** in `helm.sh/hook-delete-policy` (alongside `before-hook-creation`). |
| identityService.agentRegistration.backoffLimit | int | `6` | `spec.backoffLimit` for each registration Job (retries after a failed Pod). |
| identityService.agentRegistration.enabled | bool | `false` | Whether to render the agent-registration Jobs. Off by default. Safe to leave enabled across environments: the CLIs read their inputs from env vars (mounted via `envFrom`), so when an agent's key blob is absent (e.g. the identity-router client integration is disabled and its secrets are not provisioned) the release stays green rather than failing — `register-agent` skips registration and `create-tenant` skips the provider mapping. Not entirely side-effect-free, though: `create-tenant` still ensures the (empty) tenant row exists. So the secret's presence, not this flag, is the effective on/off switch for agent registration; enable it once and toggle the integration by provisioning (or not) the secret. Requires `identityService.migrations.runAsJob=true` (so migrations run as a pre-upgrade hook before this one, guaranteeing the schema exists); rendering fails fast otherwise. |
| identityService.agentRegistration.extraEnvSecrets | list | `[]` | Extra secrets to mount (via `envFrom`) into every agent Job, in addition to `identityService.secretName`. Use this to supply the secret(s) holding the agents' credential blobs and (from the istari-zitadel-configurator) their username / org id — the same pattern services use with `secretName` + `extraEnvSecrets`. Each is mounted `optional`, so a not-yet-provisioned secret leaves the release green (the CLIs no-op on the resulting empty values). |
| identityService.agentRegistration.podAnnotations | object | `{}` | Annotations for the registration Job Pod templates only (in addition to `sidecar.istio.io/inject: "false"`). |
| identityService.agentRegistration.podLabels | object | `{}` | Extra labels for the registration Job Pod templates only. |
| identityService.agentRegistration.resources | object | `{}` | Resources for the registration Job containers. |
| identityService.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| identityService.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| identityService.autoscaling.maxReplicas | int | `2` | Maximum number of replicas |
| identityService.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| identityService.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| identityService.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| identityService.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":65532}` | Primary container's security context |
| identityService.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| identityService.enabled | bool | `false` | Enable / Disable the whole deployment |
| identityService.env | list | `[]` |  |
| identityService.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| identityService.identityRouterClientRegistration | object | (see fields below) | Settings for the `register-client` one-shot hook Job (pre-install/pre-upgrade) that registers the registry-service's identity-service client in the identity-service ClientStore (required once the deployed identity-service image enforces client authentication on `/oauth/v2/introspect`). The Job is rendered only when BOTH `identityService.enabled` and `identityService.identityRouterClientRegistration.enabled` are `true`. It reads both `ISTARI_DIGITAL_IDENTITY_SERVICE_REGISTRY_CLIENT` (the public-only client blob) and `ISTARI_DIGITAL_IDENTITY_SERVICE_DATABASE_URL` from `identityService.secretName`, so the identity-service never needs read access to the registry-service's secret. |
| identityService.identityRouterClientRegistration.autoCleanupSuccessfulJob | bool | `true` | Automatically clean up the successful registration hook `Job` by including **`hook-succeeded`** in `helm.sh/hook-delete-policy` (alongside `before-hook-creation`). |
| identityService.identityRouterClientRegistration.backoffLimit | int | `6` | `spec.backoffLimit` for the registration Job (number of retries after a failed Pod). |
| identityService.identityRouterClientRegistration.enabled | bool | `false` | Whether to render the registration Job. Off by default: only enable in environments where the registry-service identity-service integration is turned on (so `identityService.secretName` actually contains `ISTARI_DIGITAL_IDENTITY_SERVICE_REGISTRY_CLIENT`). Otherwise the hook Job fails the release with a missing-secret-key error. |
| identityService.identityRouterClientRegistration.podAnnotations | object | `{}` | Annotations for the registration Job Pod template only (in addition to `sidecar.istio.io/inject: "false"`). |
| identityService.identityRouterClientRegistration.podLabels | object | `{}` | Extra labels for the registration Job Pod template only. |
| identityService.identityRouterClientRegistration.resources | object | `{}` | Resources for the registration Job container. |
| identityService.image | string | `"identity-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| identityService.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| identityService.ingress.annotations | object | `{}` | Annotations on the Ingress. Use this for controller-specific behavior (cert-manager, nginx, ALB, etc.). |
| identityService.ingress.className | string | `""` | `ingressClassName` on the Ingress. Leave empty to use the cluster's default IngressClass. |
| identityService.ingress.enabled | bool | `false` | Create a Kubernetes Ingress for this service. The cluster must have an Ingress controller (nginx, ALB / EKS Auto Mode, GCE, Traefik, etc.) that watches the chosen IngressClass. |
| identityService.ingress.hosts | list | `[{"host":"identity-service.istari.customer-domain.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | One entry per `spec.rules[]`. `host` is optional — when omitted, the rule matches any host. |
| identityService.ingress.labels | object | `{}` | Additional labels on the Ingress (in addition to the standard identity-service labels). |
| identityService.ingress.servicePort | int | `80` | Service port the Ingress targets. Defaults to 80. |
| identityService.ingress.tls | list | `[]` | TLS configuration; passed through to `spec.tls[]` verbatim. |
| identityService.migrations.autoCleanupSuccessfulJob | bool | `true` | Automatically clean up the successful migration hook `Job` by including **`hook-succeeded`** in `helm.sh/hook-delete-policy` (alongside `before-hook-creation`). When `true`, Helm may remove the Job after the migration succeeds (less clutter; logs are shorter-lived on the cluster). When `false`, only `before-hook-creation` is set, so the completed Job (and its Pods) remain until the next install or upgrade replaces the hook—useful for auditing or inspecting migration logs. |
| identityService.migrations.backoffLimit | int | `0` | `spec.backoffLimit` for the migration `Job` (number of retries after a failed Pod). `0` means no retries. |
| identityService.migrations.podAnnotations | object | `{}` | Annotations for the migration Job Pod template only (e.g. `sidecar.istio.io/inject: "false"` to disable Istio sidecar injection). |
| identityService.migrations.podLabels | object | `{}` | Extra labels for the migration Job Pod template only (in addition to the standard identity-service labels). |
| identityService.migrations.resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Resources for migration containers, used by both the Deployment `initContainer` and the Helm hook `Job`. |
| identityService.migrations.runAsJob | bool | `false` | Run database migrations as a Helm `pre-install` / `pre-upgrade` Job instead of a Deployment `initContainer`. When `true`, a `Job` runs `/migrate` once per release before the identity-service Deployment rolls out; the identity-service `ServiceAccount` and env `ConfigMap` are annotated with the same hooks so they exist before the Job runs. When `false`, migrations run in an `initContainer` on each identity-service Pod before the main container starts (legacy behavior). |
| identityService.nodeSelector | object | `{}` | Node selector |
| identityService.podAnnotations | object | `{}` | Additional annotations to add to pods |
| identityService.podLabels | object | `{}` | Additional labels to add to pods |
| identityService.podSecurityContext | object | `{"fsGroup":65532}` | Pod security context |
| identityService.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| identityService.replicaCount | int | `1` | Replica count |
| identityService.resources | object | `{}` |  |
| identityService.restartPolicy | string | `"Always"` | Restart policy |
| identityService.secretName | string | `"istari-identity-service"` | Secret name. The secret should contain the environment variables required by the service. |
| identityService.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| identityService.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| identityService.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| identityService.tag | string | `"1.0.2"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| identityService.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| identityService.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| identityService.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| identityService.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| identityService.virtualService.hosts | list | `["identity-service.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| identityService.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard identity-service labels). |
| identityService.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| identityService.volumes | list | `[]` | Pod Volumes |
| imagePullSecrets[0].name | string | `"docker-pull-secret"` |  |
| jaeger.enabled | bool | `false` | Enable / Disable the Jaeger subchart. When `false`, the subchart is not rendered at all and no OTEL env vars are injected into fileservice or identity-service. |
| jaeger.fullnameOverride | string | `"jaeger"` | Override the Jaeger resource name prefix. With the default `jaeger`, the in-cluster OTLP endpoints are `http://jaeger:4317` (gRPC) and `http://jaeger:4318` (HTTP). The injected `OTEL_EXPORTER_OTLP_ENDPOINT` values and the post-install notes track this override automatically. |
| jaeger.jaeger.extraEnv | list | `[{"name":"OTEL_TRACES_SAMPLER","value":"always_off"}]` | Extra env for the Jaeger container. `OTEL_TRACES_SAMPLER=always_off` disables Jaeger v2's self-tracing: the OpenTelemetry Collector SDK inside Jaeger otherwise traces its own query/ingest operations, storing them alongside real traces (every UI search generates `jaeger` spans) and exporting them to any external OTLP destination (e.g. an OpenTelemetry Collector fanning traces out to Datadog). Ingestion of application traces is unaffected — the sampler only governs Jaeger's own internal SDK. Remove this entry if you need Jaeger's internal traces to debug Jaeger itself. |
| jaeger.jaeger.extraVolumeMounts | list | `[{"mountPath":"/badger","name":"badger-data"}]` | Mounts the Badger storage volume at the path referenced by `jaeger.userconfig`. |
| jaeger.jaeger.extraVolumes | list | `[{"name":"badger-data","persistentVolumeClaim":{"claimName":"jaeger-badger"}}]` | Volumes for the Badger storage directories. References the `jaeger-badger` PVC created by this chart when `jaeger.persistence.enabled` is true — keep the claim name in sync if you change `jaeger.persistence`. |
| jaeger.jaeger.image.pullSecrets | list | `["docker-pull-secret"]` | Image pull secret names applied to the Jaeger Pod. The umbrella chart's top-level `imagePullSecrets` does not propagate to subcharts, so this is set explicitly. Defaults to `docker-pull-secret` to match the rest of the istari-platform chart. |
| jaeger.jaeger.image.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Jaeger image registry. Defaults to the Istari customer-docker JFrog repo. |
| jaeger.jaeger.image.repository | string | `"istaridigital.com/jaeger-all-in-one-fips"` | Jaeger image repository. Defaults to the Chainguard FIPS variant of Jaeger v2 (the `2.x` tags of this repo are the Jaeger v2 binary). |
| jaeger.jaeger.image.tag | string | `"2.17.0"` | Jaeger image tag. |
| jaeger.jaeger.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true}` | Container `securityContext` for the Jaeger container, matching the hardening applied to the rest of the istari-platform chart. The subchart's default Pod-level securityContext (uid/gid/fsGroup 10001) is kept so the Badger PVC is writable by the non-root user. |
| jaeger.persistence.annotations | object | `{}` | Additional annotations for the Badger PVC. |
| jaeger.persistence.enabled | bool | `true` | Create a PersistentVolumeClaim named `jaeger-badger` for Badger trace storage. The PVC is deleted on `helm uninstall` (trace history is disposable). Note: block-storage PVCs are zonal on AWS/Azure — the Jaeger Pod becomes pinned to the volume's availability zone (on Azure, a ZRS storage class avoids this). Disable only if you also switch `jaeger.userconfig` to in-memory storage and set `jaeger.jaeger.extraVolumes` / `jaeger.jaeger.extraVolumeMounts` to `[]` (see the `jaeger.userconfig` comment for the full recipe; the chart refuses to render a half-configured state). |
| jaeger.persistence.size | string | `"10Gi"` | Size of the Badger PVC. Retention is TIME-based only (`ttl.spans` in `jaeger.userconfig`, default 72h): Badger does NOT evict old data under disk pressure. A full volume stops trace collection and can wedge Badger's garbage collection (reclaiming space itself needs free disk), potentially crash-looping the Pod. Size with headroom — 10Gi over 72h ≈ 40 KB/s of stored spans, and expired data is reclaimed lazily — and alert on PVC usage (`kubelet_volume_stats_used_bytes`) around 80%. Increasing this value expands the volume in place when the StorageClass allows expansion; to reduce trace volume, lower `ttl.spans` or sample at the source. Trace history is disposable: deleting the PVC and restarting the Pod is a valid recovery. |
| jaeger.persistence.storageClassName | string | `""` | StorageClass for the Badger PVC. Empty string uses the cluster's default StorageClass. |
| jaeger.userconfig | object | `{"exporters":{"jaeger_storage_exporter":{"trace_storage":"primary_store"}},"extensions":{"healthcheckv2":{"http":{"endpoint":"0.0.0.0:13133"},"use_v2":true},"jaeger_query":{"storage":{"traces":"primary_store"}},"jaeger_storage":{"backends":{"primary_store":{"badger":{"directories":{"keys":"/badger/keys","values":"/badger/values"},"ephemeral":false,"ttl":{"spans":"72h"}}}}}},"processors":{"batch":{}},"receivers":{"otlp":{"protocols":{"grpc":{"endpoint":"0.0.0.0:4317"},"http":{"endpoint":"0.0.0.0:4318"}}}},"service":{"extensions":["jaeger_storage","jaeger_query","healthcheckv2"],"pipelines":{"traces":{"exporters":["jaeger_storage_exporter"],"processors":["batch"],"receivers":["otlp"]}}}}` | Jaeger v2 configuration (passed to the binary via `--config`). REQUIRED: without a config file Jaeger v2 binds OTLP to localhost only (unreachable from other Pods) and serves no health endpoint on port 13133, so the subchart's probes would crash-loop the Pod. This default enables OTLP gRPC/HTTP ingest on all interfaces, the query UI, and Badger storage with a 72h span TTL. To use ephemeral in-memory storage instead: replace the `badger:` block with `memory: {max_traces: 100000}`, set `jaeger.jaeger.extraVolumes`/`extraVolumeMounts` to `[]`, and set `jaeger.persistence.enabled: false`. |
| mcp.affinity | object | `{}` | Affinity |
| mcp.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| mcp.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| mcp.autoscaling.maxReplicas | int | `3` | Maximum number of replicas |
| mcp.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| mcp.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| mcp.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| mcp.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":65532}` | Primary container's security context |
| mcp.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| mcp.enabled | bool | `false` | Enable / Disable the whole deployment |
| mcp.env | list | `[]` |  |
| mcp.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| mcp.image | string | `"mcp-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| mcp.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| mcp.ingress.annotations | object | `{}` | Annotations on the Ingress. Use this for controller-specific behavior (cert-manager, nginx, ALB, etc.). |
| mcp.ingress.className | string | `""` | `ingressClassName` on the Ingress. Leave empty to use the cluster's default IngressClass. |
| mcp.ingress.enabled | bool | `false` | Create a Kubernetes Ingress for this service. The cluster must have an Ingress controller (nginx, ALB / EKS Auto Mode, GCE, Traefik, etc.) that watches the chosen IngressClass. |
| mcp.ingress.hosts | list | `[{"host":"mcp.istari.customer-domain.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | One entry per `spec.rules[]`. `host` is optional — when omitted, the rule matches any host. |
| mcp.ingress.labels | object | `{}` | Additional labels on the Ingress (in addition to the standard mcp labels). |
| mcp.ingress.servicePort | int | `80` | Service port the Ingress targets. Defaults to 80. |
| mcp.ingress.tls | list | `[]` | TLS configuration; passed through to `spec.tls[]` verbatim. |
| mcp.nodeSelector | object | `{}` | Node selector |
| mcp.podAnnotations | object | `{}` | Additional annotations to add to pods |
| mcp.podLabels | object | `{}` | Additional labels to add to pods |
| mcp.podSecurityContext | object | `{"fsGroup":65532}` | Pod security context |
| mcp.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| mcp.replicaCount | int | `1` | Replica count |
| mcp.resources | object | `{}` |  |
| mcp.restartPolicy | string | `"Always"` | Restart policy |
| mcp.secretName | string | `"istari-mcp"` | Secret name. The secret should contain the environment variables required by the service. Note that a ConfigMap is also automatically created & used with the correct value for ISTARI_DIGITAL_REGISTRY_SERVICE_URL |
| mcp.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| mcp.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| mcp.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| mcp.tag | string | `"0.4.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| mcp.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| mcp.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| mcp.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| mcp.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| mcp.virtualService.hosts | list | `["mcp.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| mcp.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard mcp labels). |
| mcp.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| mcp.volumes | list | `[]` | Pod Volumes |
| nameOverride | string | `""` | Override the value used for the label 'app.kubernetes.io/name', which defaults to the chart name (istari-platform). |
| nats.config.cluster.enabled | bool | `true` | Enable NATS clustering for HA. Defaults to `true` to match the production deployment pattern. |
| nats.config.jetstream.enabled | bool | `true` | Enable JetStream (NATS persistence layer). Required by fileservice. |
| nats.config.merge.authorization.token | string | `"<< $NATS_AUTH_TOKEN >>"` | NATS auth token. The `<< $NATS_AUTH_TOKEN >>` placeholder is substituted at startup with the value of the `NATS_AUTH_TOKEN` env var (set below from your Kubernetes Secret). |
| nats.container.env | object | `{"NATS_AUTH_TOKEN":{"valueFrom":{"secretKeyRef":{"key":"NATS_AUTH_TOKEN","name":"istari-nats"}}}}` | Container env. The `NATS_AUTH_TOKEN` value is wired to the user-managed Secret (default: `istari-nats` / key `NATS_AUTH_TOKEN`). Override `secretKeyRef.name` and `secretKeyRef.key` if your Secret uses a different name or key. |
| nats.container.image.repository | string | `"istaridigital.jfrog.io/customer-docker/istaridigital.com/nats-fips"` | NATS server image repository. Defaults to the Chainguard FIPS variant in the Istari customer-docker JFrog repo. |
| nats.container.image.tag | string | `"2.14.1"` | NATS server image tag. |
| nats.enabled | bool | `false` | Enable / Disable the NATS subchart. **Beta** — currently optional but will become required in a future release. When `false`, the subchart is not rendered at all and no NATS env vars are injected into fileservice. |
| nats.fullnameOverride | string | `"nats"` | Override the NATS resource name prefix. With the default `nats`, the in-cluster Service is reachable at `nats://nats:4222` (the URL this chart injects as `FILE_SERVICE_NATS_URL`). Change this only if you also override `fileservice.env` with a matching URL. |
| nats.global.image.pullSecretNames | list | `["docker-pull-secret"]` | Image pull secret names applied to every Pod created by the NATS subchart. The umbrella chart's top-level `imagePullSecrets` does not propagate to subcharts, so this is set explicitly. Defaults to `docker-pull-secret` to match the rest of the istari-platform chart. |
| nats.natsBox.container.image.repository | string | `"istaridigital.jfrog.io/customer-docker/istaridigital.com/nats-box-fips"` | nats-box image repository. Defaults to the Chainguard FIPS variant. |
| nats.natsBox.container.image.tag | string | `"0.19.5"` | nats-box image tag. |
| nats.natsBox.enabled | bool | `true` | Deploy the `nats-box` utility container (lightweight client for debugging from inside the cluster). |
| nats.podTemplate.merge.spec.securityContext | object | `{"fsGroup":65532}` | `securityContext` applied to NATS Pods. `fsGroup: 65532` matches the rest of the chart so JetStream PVCs are writable by the non-root NATS user. |
| nats.promExporter.enabled | bool | `false` | Deploy the NATS Prometheus exporter sidecar. Enable when scraping NATS metrics via a PodMonitor/ServiceMonitor. |
| nats.promExporter.image.repository | string | `"istaridigital.jfrog.io/customer-docker/istaridigital.com/prometheus-nats-exporter-fips"` | Prometheus exporter image repository. Defaults to the Chainguard FIPS variant. |
| nats.promExporter.image.tag | string | `"0.19.2"` | Prometheus exporter image tag. |
| nats.reloader.enabled | bool | `true` | Deploy the NATS config-reloader sidecar (recommended). Reloads NATS config on ConfigMap changes without restarting the StatefulSet. |
| nats.reloader.image.repository | string | `"istaridigital.jfrog.io/customer-docker/istaridigital.com/nats-server-config-reloader-fips"` | Config-reloader image repository. Defaults to the Chainguard FIPS variant. |
| nats.reloader.image.tag | string | `"0.23.0"` | Config-reloader image tag. |
| nats.statefulSet.merge.spec.persistentVolumeClaimRetentionPolicy | object | `{"whenDeleted":"Delete","whenScaled":"Delete"}` | Delete the JetStream PVCs when the StatefulSet is deleted or scaled down. Set to `Retain` if you need the data to outlive the StatefulSet. |
| secureConnection.affinity | object | `{}` | Affinity |
| secureConnection.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| secureConnection.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| secureConnection.autoscaling.maxReplicas | int | `2` | Maximum number of replicas |
| secureConnection.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| secureConnection.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| secureConnection.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| secureConnection.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":65532}` | Primary container's security context |
| secureConnection.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| secureConnection.enabled | bool | `false` | Enable / Disable the whole deployment |
| secureConnection.env | list | `[]` |  |
| secureConnection.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| secureConnection.image | string | `"secure-connection-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| secureConnection.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| secureConnection.ingress.annotations | object | `{}` | Annotations on the Ingress. Use this for controller-specific behavior (cert-manager, nginx, ALB, etc.). |
| secureConnection.ingress.className | string | `""` | `ingressClassName` on the Ingress. Leave empty to use the cluster's default IngressClass. |
| secureConnection.ingress.enabled | bool | `false` | Create a Kubernetes Ingress for this service. The cluster must have an Ingress controller (nginx, ALB / EKS Auto Mode, GCE, Traefik, etc.) that watches the chosen IngressClass. |
| secureConnection.ingress.hosts | list | `[{"host":"secure-connection.istari.customer-domain.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | One entry per `spec.rules[]`. `host` is optional — when omitted, the rule matches any host. |
| secureConnection.ingress.labels | object | `{}` | Additional labels on the Ingress (in addition to the standard secure-connection labels). |
| secureConnection.ingress.servicePort | int | `80` | Service port the Ingress targets. Defaults to 80. |
| secureConnection.ingress.tls | list | `[]` | TLS configuration; passed through to `spec.tls[]` verbatim. |
| secureConnection.migrations.autoCleanupSuccessfulJob | bool | `true` | Automatically clean up the successful migration hook `Job` by including **`hook-succeeded`** in `helm.sh/hook-delete-policy` (alongside `before-hook-creation`). When `true`, Helm may remove the Job after the migration succeeds (less clutter; logs are shorter-lived on the cluster). When `false`, only `before-hook-creation` is set, so the completed Job (and its Pods) remain until the next install or upgrade replaces the hook—useful for auditing or inspecting migration logs. |
| secureConnection.migrations.backoffLimit | int | `0` | `spec.backoffLimit` for the migration `Job` (number of retries after a failed Pod). `0` means no retries. |
| secureConnection.migrations.podAnnotations | object | `{}` | Annotations for the migration Job Pod template only (e.g. `sidecar.istio.io/inject: "false"` to disable Istio sidecar injection). |
| secureConnection.migrations.podLabels | object | `{}` | Extra labels for the migration Job Pod template only (in addition to the standard secure-connection labels). |
| secureConnection.migrations.runAsJob | bool | `false` | Run Alembic database migrations as a Helm `pre-install` / `pre-upgrade` Job instead of a Deployment `initContainer`. When `true`, a `Job` runs `alembic upgrade head` once per release before the secure-connection Deployment rolls out; the secure-connection `ServiceAccount` and env `ConfigMap` are annotated with the same hooks so they exist before the Job runs. When `false`, migrations run in an `initContainer` on each secure-connection Pod before the main container starts (legacy behavior). |
| secureConnection.nodeSelector | object | `{}` | Node selector |
| secureConnection.podAnnotations | object | `{}` | Additional annotations to add to pods |
| secureConnection.podLabels | object | `{}` | Additional labels to add to pods |
| secureConnection.podSecurityContext | object | `{"fsGroup":65532}` | Pod security context |
| secureConnection.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| secureConnection.replicaCount | int | `1` | Replica count |
| secureConnection.resources | object | `{}` |  |
| secureConnection.restartPolicy | string | `"Always"` | Restart policy |
| secureConnection.secretName | string | `"istari-secure-connection"` | Secret name. The secret should contain the environment variables required by the service. |
| secureConnection.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| secureConnection.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| secureConnection.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| secureConnection.tag | string | `"10.21.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| secureConnection.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| secureConnection.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| secureConnection.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| secureConnection.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| secureConnection.virtualService.hosts | list | `["secure-connection.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| secureConnection.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard secure-connection labels). |
| secureConnection.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| secureConnection.volumes | list | `[]` | Pod Volumes |
| trustedCertBundle | string | `""` | Optional: Trusted certificate bundle for when using a self-signed certificate. This is a PEM-encoded certificate bundle. AWS, Azure, and GCP root certs will also automatically be trusted. |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Istari Digital Infrastructure Team | <infra@istaridigital.com> |  |

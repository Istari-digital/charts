# istari-platform

![Version: 3.17.1](https://img.shields.io/badge/Version-3.17.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 10.x.x](https://img.shields.io/badge/AppVersion-10.x.x-informational?style=flat-square)

An umbrella helm chart used to install all Kubernetes components of the Istari Digital Platform's control plane.

## Installation

>[!NOTE]
>Pulling the chart requires access to Istari Digital's Artifactory.
>Please contact the [Support Team](mailto:support@istaridigital.com) for more information.

Instructions for installing the istari-platform chart are available in the IT Admins section of the [official Istari Documentation](https://docs.istaridigital.com/).

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://nats-io.github.io/k8s/helm/charts/ | nats | 2.14.0 |

> [!NOTE]
> The `nats` dependency is **optional** and conditional on `nats.enabled` (default `false`). When NATS is disabled, the subchart is not rendered and no NATS resources are installed. `helm dependency update` will still fetch the chart so the lockfile resolves, but it has no effect at install time unless enabled. See the `nats:` block under [Values](#values) for details.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonLabels | object | `{}` | Additional labels to add to all resources of all services |
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
| docs.tag | string | `"6.13"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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
| fileservice.tag | string | `"10.17.2"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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
| frontend.tag | string | `"8.33.5"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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
| identityService.tag | string | `"0.0.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| identityService.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| identityService.virtualService.annotations | object | `{}` | Annotations on the VirtualService. |
| identityService.virtualService.enabled | bool | `false` | Create an Istio VirtualService for this service. Requires Istio installed in the cluster with the `networking.istio.io/v1` CRD (Istio 1.22+). |
| identityService.virtualService.gateways | list | `[]` | `spec.gateways[]` — Gateway resources to attach to. Use `<namespace>/<gateway-name>` to reference a Gateway in another namespace. Leave empty for mesh-internal traffic only. |
| identityService.virtualService.hosts | list | `["identity-service.example.com"]` | `spec.hosts[]` — DNS names this VirtualService matches (FQDNs, or short names for mesh-internal traffic). The default below is an EXAMPLE — you MUST replace it with your actual hostname(s) before enabling the VirtualService. Clearing this list while `enabled: true` will cause the chart to fail to render. |
| identityService.virtualService.labels | object | `{}` | Additional labels on the VirtualService (in addition to the standard identity-service labels). |
| identityService.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| identityService.volumes | list | `[]` | Pod Volumes |
| imagePullSecrets[0].name | string | `"docker-pull-secret"` |  |
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
| mcp.tag | string | `"0.3.3"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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
| secureConnection.tag | string | `"10.17.2"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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

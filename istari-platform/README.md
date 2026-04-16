# istari-platform

![Version: 3.9.0](https://img.shields.io/badge/Version-3.9.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 10.x.x](https://img.shields.io/badge/AppVersion-10.x.x-informational?style=flat-square)

An umbrella helm chart used to install all Kubernetes components of the Istari Digital Platform's control plane.

## Installation

>[!NOTE]
>Pulling the chart requires access to Istari Digital's Artifactory.
>Please contact the [Support Team](mailto:support@istaridigital.com) for more information.

Instructions for installing the istari-platform chart are available in the IT Admins section of the [official Istari Documentation](https://docs.istaridigital.com/).

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
| docs.tag | string | `"6.11.0"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| docs.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
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
| fileservice.migrations.autoCleanupSuccessfulJob | bool | `true` | Automatically clean up the successful migration hook `Job` by including **`hook-succeeded`** in `helm.sh/hook-delete-policy` (alongside `before-hook-creation`). When `true`, Helm may remove the Job after the migration succeeds (less clutter; logs are shorter-lived on the cluster). When `false`, only `before-hook-creation` is set, so the completed Job (and its Pods) remain until the next install or upgrade replaces the hook—useful for auditing or inspecting migration logs. |
| fileservice.migrations.backoffLimit | int | `0` | `spec.backoffLimit` for the migration `Job` (number of retries after a failed Pod). `0` means no retries. |
| fileservice.migrations.podAnnotations | object | `{}` | Annotations for the migration Job Pod template only (e.g. `sidecar.istio.io/inject: "false"` to disable Istio sidecar injection). |
| fileservice.migrations.podLabels | object | `{}` | Extra labels for the migration Job Pod template only (in addition to the standard fileservice labels). |
| fileservice.migrations.runAsJob | bool | `false` | Run Alembic database migrations as a Helm `pre-install` / `pre-upgrade` Job instead of a Deployment `initContainer`. When `true`, a `Job` runs `alembic upgrade head` once per release before the fileservice Deployment rolls out; the fileservice `ServiceAccount` is annotated with the same hooks so it exists before the Job runs. When `false`, migrations run in an `initContainer` on each fileservice Pod before the main container starts (legacy behavior). |
| fileservice.nodeSelector | object | `{}` | Node selector |
| fileservice.podAnnotations | object | `{}` | Additional annotations to add to pods |
| fileservice.podLabels | object | `{}` | Additional labels to add to pods |
| fileservice.podSecurityContext | object | `{"fsGroup":65532}` | Pod security context |
| fileservice.prometheusAutodiscoveryAnnotations | bool | `true` | Prometheus autodiscovery annotations. If true, the following annotations will be added to the service prometheus.io/scrape: "true" prometheus.io/port: "8000" prometheus.io/path: "/stats/prometheus" |
| fileservice.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.replicaCount | int | `1` | Replica count |
| fileservice.resources | object | `{}` |  |
| fileservice.restartPolicy | string | `"Always"` | Restart policy |
| fileservice.secretName | string | `"istari-fileservice"` | Secret name. The secret should contain the environment variables required by the service. |
| fileservice.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| fileservice.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| fileservice.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| fileservice.tag | string | `"10.12.10"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
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
| frontend.tag | string | `"8.26.0"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| frontend.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| frontend.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| frontend.volumes | list | `[]` | Pod Volumes |
| fullnameOverride | string | `"istari"` | Override the prefix used for resource names, which defaults to the chart name (istari-platform). |
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
| mcp.tag | string | `"0.3.0"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| mcp.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| mcp.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| mcp.volumes | list | `[]` | Pod Volumes |
| nameOverride | string | `""` | Override the value used for the label 'app.kubernetes.io/name', which defaults to the chart name (istari-platform). |
| secureConnection.affinity | object | `{}` | Affinity |
| secureConnection.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| secureConnection.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| secureConnection.autoscaling.maxReplicas | int | `2` | Maximum number of replicas |
| secureConnection.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| secureConnection.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| secureConnection.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| secureConnection.containerSecurityContext | object | `{}` | Primary container's security context |
| secureConnection.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| secureConnection.enabled | bool | `false` | Enable / Disable the whole deployment |
| secureConnection.env | list | `[]` |  |
| secureConnection.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| secureConnection.image | string | `"secure-connection-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| secureConnection.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| secureConnection.nodeSelector | object | `{}` | Node selector |
| secureConnection.podAnnotations | object | `{}` | Additional annotations to add to pods |
| secureConnection.podLabels | object | `{}` | Additional labels to add to pods |
| secureConnection.podSecurityContext | object | `{}` | Pod security context |
| secureConnection.prometheusAutodiscoveryAnnotations | bool | `true` | Prometheus autodiscovery annotations. If true, the following annotations will be added to the service prometheus.io/scrape: "true" prometheus.io/port: "80" prometheus.io/path: "/stats/prometheus" |
| secureConnection.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| secureConnection.replicaCount | int | `1` | Replica count |
| secureConnection.resources | object | `{}` |  |
| secureConnection.restartPolicy | string | `"Always"` | Restart policy |
| secureConnection.secretName | string | `"istari-secure-connection"` | Secret name. The secret should contain the environment variables required by the service. |
| secureConnection.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| secureConnection.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| secureConnection.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| secureConnection.tag | string | `"10.12.10"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| secureConnection.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| secureConnection.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| secureConnection.volumes | list | `[]` | Pod Volumes |
| trustedCertBundle | string | `""` | Optional: Trusted certificate bundle for when using a self-signed certificate. This is a PEM-encoded certificate bundle. AWS, Azure, and GCP root certs will also automatically be trusted. |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Istari Digital Infrastructure Team | <infra@istaridigital.com> |  |

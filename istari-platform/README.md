# istari-platform

![Version: 3.4.0](https://img.shields.io/badge/Version-3.4.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 6.x.x](https://img.shields.io/badge/AppVersion-6.x.x-informational?style=flat-square)

An umbrella helm chart used to install all Kubernetes components of the Istari Platform's control plane.

## Installation

>[!NOTE]
>Istari needs to grant access to the Istari Artifactory to allow customers to pull the istari-platform helm chart.
>Please contact [Support Team](mailto:support@istaridigital.com) for more information.

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
| docs.tag | string | `"6.9.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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
| fileservice.containerSecurityContext | object | `{}` | Primary container's security context |
| fileservice.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| fileservice.enabled | bool | `true` | Enable / Disable the whole deployment |
| fileservice.env | list | `[]` |  |
| fileservice.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| fileservice.image | string | `"fileservice2"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| fileservice.nodeSelector | object | `{}` | Node selector |
| fileservice.podAnnotations | object | `{}` | Additional annotations to add to pods |
| fileservice.podLabels | object | `{}` | Additional labels to add to pods |
| fileservice.podSecurityContext | object | `{}` | Pod security context |
| fileservice.prometheusAutodiscoveryAnnotations | bool | `true` | Prometheus autodiscovery annotations. If true, the following annotations will be added to the service prometheus.io/scrape: "true" prometheus.io/port: "8000" prometheus.io/path: "/stats/prometheus" |
| fileservice.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| fileservice.replicaCount | int | `1` | Replica count |
| fileservice.resources | object | `{}` |  |
| fileservice.restartPolicy | string | `"Always"` | Restart policy |
| fileservice.secretName | string | `"istari-fileservice"` | Secret name. The secret should contain the environment variables required by the service. |
| fileservice.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| fileservice.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| fileservice.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| fileservice.tag | string | `"10.9.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
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
| frontend.tag | string | `"8.20.1"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| frontend.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| frontend.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| frontend.volumes | list | `[]` | Pod Volumes |
| fullnameOverride | string | `"istari"` | Override the prefix used for resource names, which defaults to the chart name (istari-platform). |
| imagePullSecrets[0].name | string | `"docker-pull-secret"` |  |
| magicDocs.affinity | object | `{}` | Affinity |
| magicDocs.autoscaling.cpuUtilization | int | `80` | Average CPU utilization percentage. Set to `null` to disable. |
| magicDocs.autoscaling.enabled | bool | `false` | Enable/Disable autoscaling |
| magicDocs.autoscaling.maxReplicas | int | `2` | Maximum number of replicas |
| magicDocs.autoscaling.memoryUtilization | int | `80` | Average Memory utilization percentage. Set to `null` to disable. |
| magicDocs.autoscaling.minReplicas | int | `1` | Minimum number of replicas |
| magicDocs.commonLabels | object | `{}` | Additional labels to add to all of this service's resources |
| magicDocs.containerSecurityContext | object | `{"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":1000}` | Primary container's security context |
| magicDocs.deploymentAnnotations | object | `{}` | Additional annotations to add to the deployment |
| magicDocs.enabled | bool | `false` | Enable / Disable the whole deployment |
| magicDocs.env | list | `[]` |  |
| magicDocs.extraEnvSecrets | list | `[]` | Extra secrets to mount in the pod. The secrets should contain the environment variables required by the service. |
| magicDocs.image | string | `"magic-docs-service"` | Image name. The combination of registry, image, and tag will be used to pull the image. |
| magicDocs.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy |
| magicDocs.nodeSelector | object | `{}` | Node selector |
| magicDocs.podAnnotations | object | `{}` | Additional annotations to add to pods |
| magicDocs.podLabels | object | `{}` | Additional labels to add to pods |
| magicDocs.podSecurityContext | object | `{"fsGroup":2000}` | Pod security context |
| magicDocs.registry | string | `"istaridigital.jfrog.io/customer-docker"` | Registry URL for images. The combination of registry, image, and tag will be used to pull the image. |
| magicDocs.replicaCount | int | `1` | Replica count |
| magicDocs.resources | object | `{}` |  |
| magicDocs.restartPolicy | string | `"Always"` | Restart policy |
| magicDocs.secretName | string | `"istari-magic-docs"` | Secret name. The secret should contain the environment variables required by the service. |
| magicDocs.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| magicDocs.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| magicDocs.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| magicDocs.tag | string | `"3.3.12"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| magicDocs.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| magicDocs.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| magicDocs.volumes | list | `[]` | Pod Volumes |
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
| mcp.replicaCount | int | `2` | Replica count |
| mcp.resources | object | `{}` |  |
| mcp.restartPolicy | string | `"Always"` | Restart policy |
| mcp.secretName | string | `"istari-mcp"` | Secret name. The secret should contain the environment variables required by the service. Note that a ConfigMap is also automatically created & used with the correct value for ISTARI_DIGITAL_REGISTRY_SERVICE_URL |
| mcp.serviceAccountAnnotations | object | `{}` | Additional annotations to apply to the service account |
| mcp.serviceAnnotations | object | `{}` | Additional annotations to apply to the service, note the following annotations for duplicate keys. |
| mcp.serviceType | string | `"ClusterIP"` | Service Type. Available options are ClusterIP, NodePort, LoadBalancer, ExternalName. |
| mcp.tag | string | `"0.1.52"` | Image tag. The combination of registry, image, and tag will be used to pull the image. |
| mcp.tolerations | list | `[]` | Tolerations. Example:  ``` tolerations: - "effect": "NoSchedule"   "key": "istari.k8s.io/role"   "operator": "Equal"   "value": "main" ``` |
| mcp.volumeMounts | list | `[]` | Volume Mounts for pod containers |
| mcp.volumes | list | `[]` | Pod Volumes |
| nameOverride | string | `""` | Override the value used for the label 'app.kubernetes.io/name', which defaults to the chart name (istari-platform). |
| trustedCertBundle | string | `""` | Optional: Trusted certificate bundle for when using a self-signed certificate. This is a PEM-encoded certificate bundle. AWS, Azure, and GCP root certs will also automatically be trusted. |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Istari Digital Infrastructure Team | <infra@istaridigital.com> |  |

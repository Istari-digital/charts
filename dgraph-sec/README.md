# Dgraph-sec

![Version: 0.4.1](https://img.shields.io/badge/Version-0.4.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.3.4-sec.0.1.0](https://img.shields.io/badge/AppVersion-v25.3.4--sec.0.1.0-informational?style=flat-square)

Dgraph-sec — hardened Dgraph database for Istari platform

**Homepage:** <https://dgraph.io/>

This chart packages **Dgraph-sec**, the hardened fork of [Dgraph](https://dgraph.io/)
— a distributed graph database — for the Istari platform. It deploys the two
stateful Dgraph roles, **Zero** (cluster coordinator / Raft membership) and
**Alpha** (data + query serving), plus optional Ratel UI, binary-backup CronJobs,
Datadog autodiscovery, and OpenTelemetry tracing.

The chart is a fork of the upstream Dgraph chart with Istari-specific changes:
secure-by-default pod and container security contexts, the `dgraph-sec` binary and
image, Datadog/OTEL wiring, a 3-tier service-naming convention, and gated
production add-ons (PodDisruptionBudgets, NetworkPolicy, ServiceMonitor,
PrometheusRule).

## Installation

> [!NOTE]
> Pulling the chart requires access to Istari Digital's Artifactory.
> Please contact the [Support Team](mailto:support@istaridigital.com) for more information.

```bash
helm install dgraph-sec main-helm-local/dgraph-sec \
  --namespace dgraph-sec --create-namespace
```

This brings up a **working cluster out of the box**: 3 Zero + 3 Alpha replicas,
non-root pods, PodDisruptionBudgets, and — because ACL is disabled by default — no
login required, so applications can connect immediately.

In helm-stack this chart is consumed from Terraform (`istari-k8s-core/dgraph-sec.tf`)
with `fullnameOverride: dgraph-sec`, which is why the deployed objects are named
`dgraph-sec-alpha`, `dgraph-sec-zero`, etc.

## Architecture

| Role | Kind | Default replicas | Purpose |
|------|------|------------------|---------|
| Zero | StatefulSet | 3 | Cluster coordinator: membership, tablet/shard assignment, timestamp oracle (Raft). |
| Alpha | StatefulSet | 3 | Stores predicates/posting lists and serves DQL/GraphQL queries (Raft per group). |
| Ratel | Deployment | 1 (disabled) | Debug-grade web UI. Off by default — see the security note below. |
| Backups | CronJob | (disabled) | Full + incremental binary backups to filesystem / NFS / S3 / MinIO. |

`zero.shardReplicaCount` is the per-group replication factor (`--replicas`), **not** a
pod count — keep it `<= alpha.replicaCount`.

## Naming

Everything uses a single identity: **`dgraph-sec`** — the chart name, the Helm
template helpers (`dgraph-sec.*`), the `app.kubernetes.io/name` / `app` / `chart`
labels, the deployed object names, the Datadog `superservice`, and the OTEL tracing
service names. The Datadog/tracing identity follows the 3-tier
`superservice.subservice` convention (e.g. `dgraph-sec.alpha`, `dgraph-sec.zero`).

## Security posture

This is the `-sec` fork, so secure defaults are baked in:

- Pods run **non-root** (`runAsNonRoot: true`, uid/gid 1001) with a `RuntimeDefault`
  seccomp profile.
- Containers **drop all Linux capabilities** and forbid privilege escalation.
  `readOnlyRootFilesystem` is shipped `false` (dgraph writes scratch data outside its
  mounted data dir); validate on a cluster before enabling.
- `automountServiceAccountToken` is **off** everywhere — no workload calls the
  Kubernetes API.
- PodDisruptionBudgets (`minAvailable: 2`) protect Zero and Alpha quorum from
  voluntary disruptions (node drains, autoscaler scale-down).

Defaults that are **off** and must be enabled for a production posture: ACL
(authentication), encryption at rest, TLS in transit, and NetworkPolicy. See
`values.yaml` and the post-install NOTES for the exact flags.

## Backups & restore

Enable scheduled binary backups with `backups.full.enabled` / `backups.incremental.enabled`
and a `backups.destination`. Restoring is a deliberate, operator-driven action — there
is no automatic restore. The runbook lives in [`scripts/README.md`](./scripts/README.md#restoring-from-a-binary-backup).

The full and incremental backup CronJobs inherit `alpha.nodeSelector` and
`alpha.tolerations`, so each backup pod schedules onto the same node group as the
Alpha it backs up — it triggers the backup against `alpha-0` and, for filesystem/NFS
destinations, shares Alpha's backup volume. Pin Alpha to a dedicated, tainted node
group and the backups follow it there; leave `alpha` scheduling unset and they
schedule anywhere, as before.

> [!WARNING]
> Credentials (`backups.admin.password`, `backups.admin.auth_token`, ACL secrets) set
> inline in a values file are visible via `helm get values` and tend to leak into git.
> Prefer External Secrets Operator or Sealed Secrets. When ACL is enabled the chart
> **requires** `backups.admin.user` so backups can never silently fall back to the
> well-known `groot` superadmin.

## Monitoring

Alpha and Zero pods carry `prometheus.io/*` scrape annotations
(`/debug/prometheus_metrics`) for annotation-based discovery. For the Prometheus
Operator, enable `serviceMonitor.enabled` (and `prometheusRule.enabled` for default
alerts). Set `datadog.enabled` for Datadog autodiscovery + unified service tags.

## Logging

Dgraph uses glog. Each role writes `INFO` / `WARNING` / `ERROR` to stderr, where
`kubectl logs` and the node log collector capture them. Those severities are always
on; verbosity only adds finer detail on top, so a log level can climb above the
baseline but never hide a severity.

Set verbosity per role with `alpha.logLevel` / `zero.logLevel` — a named level or a
raw glog `-v` integer:

| Level | `-v` |
|-------|------|
| `normal` (default) | 0 |
| `verbose` | 1 |
| `debug` | 2 |
| `trace` | 3 |

Target one subsystem with `vmodule` (e.g. `"server=3,raft=2"`). Keep
`logtostderr: true` on Kubernetes; setting it `false` without a writable `logDir`
loses logs when a container restarts. For any glog flag the chart does not expose
(`--stderrthreshold`, `--log_backtrace_at`), append it to `extraFlags` — a `-v` set
there overrides `logLevel`.

## Tracing (OpenTelemetry)

Set `tracing.enabled` to export traces from Alpha and Zero. The chart builds Dgraph's
`--trace` superflag from the `tracing` block and sends OTLP/HTTP to the configured
collector:

| Value | Purpose |
|-------|---------|
| `tracing.endpoint` | OTLP/HTTP collector — default the Datadog agent on port 4318 |
| `tracing.ratio` | Sample fraction — default `0.01` |
| `tracing.alpha.service` / `tracing.zero.service` | Per-role service name (`dgraph-sec.alpha` / `dgraph-sec.zero`) |

In helm-stack `tracing.enabled` follows the Datadog operator, so traces flow wherever
the agent runs.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alpha.acl | object | `{"bootstrap":{"enabled":false,"existingSecret":"","grootPasswordSecretKey":"groot_password","groups":[],"image":{},"rotation":"","users":[]},"enabled":false,"existingSecret":"","secretFile":"hmac_secret_file"}` | Access Control List (ACL) configuration for alpha. |
| alpha.acl.bootstrap | object | `{"enabled":false,"existingSecret":"","grootPasswordSecretKey":"groot_password","groups":[],"image":{},"rotation":"","users":[]}` | Idempotent groot-rotation + user/group reconciler, run as a Helm hook Job. |
| alpha.acl.bootstrap.enabled | bool | `false` | Run the ACL bootstrap/reconciler Job (requires acl.enabled and a credentials Secret). |
| alpha.acl.bootstrap.existingSecret | string | `""` | Secret holding the credentials the Job reads; defaults to acl.existingSecret. |
| alpha.acl.bootstrap.grootPasswordSecretKey | string | `"groot_password"` | Key in the Secret holding groot's target (rotated) password. |
| alpha.acl.bootstrap.groups | list | `[]` | ACL groups to ensure, with predicate rules. |
| alpha.acl.bootstrap.image | object | `{}` | Image for the bootstrap Job; defaults to the dgraph-sec image (has curl + jq). |
| alpha.acl.bootstrap.rotation | string | `""` | Opaque rotation token rendered as a Job pod annotation. Change it (e.g. from    Terraform's dgraph_sec_acl_password_rotation) to force a helm upgrade that    re-runs the reconciler, without touching Alpha. Empty = no annotation. |
| alpha.acl.bootstrap.users | list | `[]` | ACL users to ensure, each with a password Secret key and group membership. |
| alpha.acl.existingSecret | string | `""` | Name of a pre-created Secret holding the HMAC (and bootstrap passwords); empty means create one from `file`. |
| alpha.acl.secretFile | string | `"hmac_secret_file"` | Filename/key of the HMAC secret; the `--acl secret-file=` flag points at /dgraph/acl/<secretFile>. |
| alpha.alsologtostderr | bool | `false` | Also write alpha logs to files under logDir (--alsologtostderr). |
| alpha.antiAffinity | string | `"soft"` | Pod anti-affinity strength for alpha (soft = best effort, hard = required). |
| alpha.automountServiceAccountToken | bool | `false` | Do not mount the API token on alpha pods; alpha never calls the K8s API. |
| alpha.configFile | object | `{}` | Config-file contents for alpha (alternative to CLI flags). |
| alpha.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":false}` | Secure-by-default container securityContext for alpha (drop ALL caps, no privilege escalation). |
| alpha.customLivenessProbe | object | `{}` | Full custom liveness probe spec for alpha (overrides livenessProbe). |
| alpha.customReadinessProbe | object | `{}` | Full custom readiness probe spec for alpha (overrides readinessProbe). |
| alpha.customStartupProbe | object | `{}` | Full custom startup probe spec for alpha (overrides startupProbe). |
| alpha.encryption | object | `{"enabled":false,"existingSecret":"","keyFile":"enc_key_file"}` | Encryption-at-rest configuration for alpha. |
| alpha.encryption.existingSecret | string | `""` | Name of a pre-created Secret holding the encryption key; empty means create one from `file`. |
| alpha.encryption.keyFile | string | `"enc_key_file"` | Filename/key of the encryption key; the `--encryption key-file=` flag points at /dgraph/enc/<keyFile>. |
| alpha.envFrom | list | `[]` | Extra envFrom sources (configMaps/secrets) for the alpha container. |
| alpha.extraAnnotations | object | `{}` | Extra annotations on the alpha StatefulSet pod template. |
| alpha.extraEnvs | list | `[]` | Extra environment variables appended to the alpha container. |
| alpha.extraFlags | string | `""` | Extra command-line flags appended to dgraph-sec alpha (logging fallthrough). |
| alpha.extraInitContainers | list | `[]` | Extra init containers for the alpha StatefulSet. |
| alpha.ingress | object | `{"enabled":false}` | HTTP Ingress for the alpha service (requires an ingress controller). |
| alpha.ingress_grpc | object | `{"enabled":false}` | gRPC Ingress for the alpha service (requires an ingress controller). |
| alpha.initContainers | object | `{"init":{"command":["bash","-c","trap \"exit\" SIGINT SIGTERM\necho \"Write to /dgraph/doneinit when ready.\"\nuntil [ -f /dgraph/doneinit ]; do sleep 2; done\n"],"enabled":false,"env":[],"envFrom":[],"image":{"<<":{"debug":false,"pullPolicy":"IfNotPresent","registry":"istaridigital.jfrog.io","repository":"main-docker-local/dgraph-sec","tag":"v25.3.4-sec.0.1.0"}}}}` | Optional alpha pre-start init container (e.g. restore or bulk load before Alpha starts). |
| alpha.initContainers.init.image.<<.debug | bool | `false` | Enable verbose BASH/NAMI image debugging output. |
| alpha.initContainers.init.image.<<.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the dgraph-sec image. |
| alpha.initContainers.init.image.<<.registry | string | `"istaridigital.jfrog.io"` | Container registry hosting the dgraph-sec image. |
| alpha.initContainers.init.image.<<.repository | string | `"main-docker-local/dgraph-sec"` | Repository path for the hardened dgraph-sec image. |
| alpha.initContainers.init.image.<<.tag | string | `"v25.3.4-sec.0.1.0"` | dgraph-sec image tag (matches the chart appVersion). |
| alpha.livenessProbe | object | `{"enabled":true,"failureThreshold":6,"initialDelaySeconds":15,"path":"/health?live=1","periodSeconds":10,"port":8080,"successThreshold":1,"timeoutSeconds":5}` | Liveness probe for alpha (against the 8080 /health?live=1 endpoint). |
| alpha.logDir | string | `""` | Directory for alpha glog file output (--log_dir); needs a writable mount. |
| alpha.logLevel | string | `"normal"` | Alpha log verbosity: named level (normal|verbose|debug|trace) or a raw glog -v integer. |
| alpha.logtostderr | bool | `true` | Send alpha logs to stderr (--logtostderr). Keep true for Kubernetes log capture. |
| alpha.metrics | object | `{"enabled":true}` | Toggle Prometheus metrics scrape annotations on alpha. |
| alpha.monitorLabel | string | `"alpha-dgraph-io"` | Value of the "monitor" label on the alpha Service for Prometheus discovery. |
| alpha.name | string | `"alpha"` | Component name for the alpha (data/query) workload. |
| alpha.nodeAffinity | object | `{}` | Node affinity rules for alpha pod scheduling. |
| alpha.nodeSelector | object | `{}` | Node selector for alpha pod scheduling. |
| alpha.pdb | object | `{"enabled":true,"minAvailable":2}` | PodDisruptionBudget protecting the alpha Raft group. |
| alpha.persistence | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"persistentVolumeClaimRetentionPolicy":{"whenDeleted":"Retain","whenScaled":"Retain"},"size":"100Gi"}` | Persistent volume claim template for alpha data. |
| alpha.persistence.persistentVolumeClaimRetentionPolicy | object | `{"whenDeleted":"Retain","whenScaled":"Retain"}` | StatefulSet PVC retention policy. whenDeleted applies on `helm uninstall`; whenScaled on replica reduction. Each "Retain" or "Delete". |
| alpha.podAntiAffinitytopologyKey | string | `"kubernetes.io/hostname"` | Topology key for alpha pod anti-affinity spreading. |
| alpha.podLabels | object | `{}` | Extra pod labels on the alpha StatefulSet. |
| alpha.podManagementPolicy | string | `"Parallel"` | Pod management policy for the alpha StatefulSet (OrderedReady or Parallel). |
| alpha.readinessProbe | object | `{"enabled":true,"failureThreshold":6,"initialDelaySeconds":15,"path":"/probe/graphql","periodSeconds":10,"port":8080,"successThreshold":1,"timeoutSeconds":5}` | Readiness probe for alpha (against the 8080 /probe/graphql endpoint). |
| alpha.replicaCount | int | `3` | Number of alpha data/query pods. |
| alpha.resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | CPU/memory requests and limits for alpha; right-size limits.memory before production. |
| alpha.securityContext | object | `{"enabled":true,"fsGroup":1001,"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001,"seccompProfile":{"type":"RuntimeDefault"}}` | Secure-by-default pod securityContext for alpha (non-root, RuntimeDefault seccomp). |
| alpha.service | object | `{"annotations":{},"externalTrafficPolicy":"","labels":{},"loadBalancerIP":"","loadBalancerSourceRanges":[],"publishNotReadyAddresses":true,"type":"ClusterIP"}` | alpha Service configuration (type, labels, annotations, load-balancer settings). |
| alpha.serviceHeadless | object | `{"labels":{}}` | Labels for the alpha headless Service. |
| alpha.startupProbe | object | `{"enabled":false,"failureThreshold":30,"path":"/health?live=1","periodSeconds":10,"port":8080,"successThreshold":1,"timeoutSeconds":5}` | Startup probe for alpha (against the 8080 /health?live=1 endpoint). |
| alpha.terminationGracePeriodSeconds | int | `600` | Termination grace period (seconds) for alpha pods. |
| alpha.tls | object | `{"enabled":false,"files":{}}` | TLS configuration for alpha (cert files generated by dgraph-sec cert). |
| alpha.tolerations | list | `[]` | Tolerations for alpha pod scheduling. |
| alpha.updateStrategy | string | `"RollingUpdate"` | StatefulSet update strategy for alpha (RollingUpdate or OnDelete). |
| alpha.vmodule | string | `""` | Alpha per-module glog verbosity (--vmodule); empty disables. |
| backups.admin | object | `{"auth_token":"","existingSecret":"","password":"","passwordSecretKey":"backup_admin_password","tls_client":"","user":""}` | Backup admin credentials/token used to trigger backups when ACLs are enabled. |
| backups.destination | string | `"/dgraph/backups"` | Backup destination: a file path, s3://, or minio:// URI. |
| backups.full | object | `{"debug":false,"enabled":false,"restartPolicy":"Never","schedule":"0 0 * * *"}` | Full-backup CronJob (enable, schedule, restart policy). |
| backups.image | object | `{"<<":{"debug":false,"pullPolicy":"IfNotPresent","registry":"istaridigital.jfrog.io","repository":"main-docker-local/dgraph-sec","tag":"v25.3.4-sec.0.1.0"}}` | Image for backup CronJobs (defaults to the shared dgraph-sec image; needs curl). |
| backups.image.<<.debug | bool | `false` | Enable verbose BASH/NAMI image debugging output. |
| backups.image.<<.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the dgraph-sec image. |
| backups.image.<<.registry | string | `"istaridigital.jfrog.io"` | Container registry hosting the dgraph-sec image. |
| backups.image.<<.repository | string | `"main-docker-local/dgraph-sec"` | Repository path for the hardened dgraph-sec image. |
| backups.image.<<.tag | string | `"v25.3.4-sec.0.1.0"` | dgraph-sec image tag (matches the chart appVersion). |
| backups.incremental | object | `{"debug":false,"enabled":false,"restartPolicy":"Never","schedule":"0 1-23 * * *"}` | Incremental-backup CronJob (enable, schedule, restart policy). |
| backups.keys | object | `{"minio":{"access":"","secret":""},"s3":{"access":"","secret":""}}` | MinIO/S3 access keys for the backup destination. |
| backups.minioSecure | bool | `false` | Use HTTPS when the MinIO endpoint is TLS-enabled. |
| backups.name | string | `"backups"` | Component name for the binary backup CronJobs. |
| backups.nfs | object | `{"enabled":false,"mountPath":"/dgraph/backups","path":"","server":"","storage":"512Gi"}` | NFS-backed PersistentVolume for backup storage mounted into Alpha pods. |
| backups.podAnnotations | object | `{}` | Extra pod annotations on the backup CronJob pod template. |
| backups.podLabels | object | `{}` | Extra pod labels on the backup CronJob pod template. |
| backups.subpath | string | `"dgraph_sec_$(date +%Y%m%d)"` | Subpath under the destination for grouping full and incremental backups. |
| backups.volume | object | `{"claim":"","enabled":false,"mountPath":"/dgraph/backups/"}` | Pre-existing PVC mounted into Alpha pods for backup storage. |
| commonLabels | object | `{}` | Labels added to every resource and pod template; lowest priority. |
| datadog | object | `{"alpha":{"subservice":"alpha"},"enabled":false,"superservice":"dgraph-sec","zero":{"subservice":"zero"}}` | Datadog autodiscovery annotations and tags (superservice/subservice naming). |
| global.domain | string | `"cluster.local"` | Cluster DNS domain used to build in-cluster service hostnames. |
| global.ingress | object | `{"alpha_hostname":null,"annotations":{},"enabled":false,"ingressClassName":null,"ratel_hostname":null,"tls":{}}` | Combined HTTP Ingress for alpha and ratel (overrides per-component ingress). |
| global.ingress_grpc | object | `{"alpha_grpc_hostname":null,"annotations":{},"enabled":false,"ingressClassName":null,"tls":{}}` | Combined gRPC Ingress for alpha (overrides per-component ingress_grpc). |
| image.debug | bool | `false` | Enable verbose BASH/NAMI image debugging output. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the dgraph-sec image. |
| image.registry | string | `"istaridigital.jfrog.io"` | Container registry hosting the dgraph-sec image. |
| image.repository | string | `"main-docker-local/dgraph-sec"` | Repository path for the hardened dgraph-sec image. |
| image.tag | string | `"v25.3.4-sec.0.1.0"` | dgraph-sec image tag (matches the chart appVersion). |
| networkPolicy | object | `{"clientPodLabels":{},"enabled":false,"extraIngress":[]}` | NetworkPolicy gating ingress to alpha/zero ports (gated production add-on). |
| preUpgradeHook.enabled | bool | `true` | Run the v24-to-v25 StatefulSet selector migration Job on helm upgrade. |
| preUpgradeHook.image | object | `{"registry":"istaridigital.jfrog.io","repository":"remote-docker-dockerhub/bitnami/kubectl","tag":"1.31"}` | kubectl image used by the pre-upgrade migration Job. |
| preUpgradeHook.podAnnotations | object | `{}` | Extra pod annotations for the pre-upgrade hook Job. |
| preUpgradeHook.podLabels | object | `{}` | Extra pod labels for the pre-upgrade hook Job. |
| prometheusRule | object | `{"defaultRules":true,"enabled":false,"extraRules":[],"labels":{}}` | Prometheus Operator PrometheusRule with default alerts (gated production add-on). |
| ratel.args | list | `[]` | Extra arguments appended to the dgraph-ratel command. |
| ratel.automountServiceAccountToken | bool | `false` | Do not mount the API token on ratel pods; ratel is a static UI. |
| ratel.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":false}` | Secure-by-default container securityContext for ratel (drop ALL caps, no privilege escalation). |
| ratel.customLivenessProbe | object | `{}` | Full custom liveness probe spec for ratel (overrides livenessProbe). |
| ratel.customReadinessProbe | object | `{}` | Full custom readiness probe spec for ratel (overrides readinessProbe). |
| ratel.enabled | bool | `false` | Deploy the ratel debug UI (off by default; never expose publicly). |
| ratel.envFrom | list | `[]` | Extra envFrom sources (configMaps/secrets) for the ratel container. |
| ratel.extraAnnotations | object | `{}` | Extra annotations on the ratel Deployment pod template. |
| ratel.extraEnvs | list | `[]` | Extra environment variables appended to the ratel container. |
| ratel.image | object | `{"registry":"istaridigital.jfrog.io","repository":"remote-docker-dockerhub/dgraph/ratel","tag":"v21.12.0"}` | Image for the ratel UI (separate dgraph/ratel image). |
| ratel.ingress | object | `{"enabled":false}` | HTTP Ingress for the ratel service (requires an ingress controller). |
| ratel.livenessProbe | object | `{"enabled":false,"failureThreshold":6,"initialDelaySeconds":30,"path":"/","periodSeconds":10,"port":8000,"successThreshold":1,"timeoutSeconds":5}` | Liveness probe for ratel (against the 8000 / endpoint). |
| ratel.name | string | `"ratel"` | Component name for the ratel debug UI workload. |
| ratel.podLabels | object | `{}` | Extra pod labels on the ratel Deployment. |
| ratel.readinessProbe | object | `{"enabled":false,"failureThreshold":6,"initialDelaySeconds":5,"path":"/","periodSeconds":10,"port":8000,"successThreshold":1,"timeoutSeconds":5}` | Readiness probe for ratel (against the 8000 / endpoint). |
| ratel.replicaCount | int | `1` | Number of ratel UI pods. |
| ratel.securityContext | object | `{"enabled":true,"fsGroup":1001,"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001,"seccompProfile":{"type":"RuntimeDefault"}}` | Secure-by-default pod securityContext for ratel (non-root, RuntimeDefault seccomp). |
| ratel.service | object | `{"annotations":{},"externalTrafficPolicy":"","labels":{},"loadBalancerIP":"","loadBalancerSourceRanges":[],"type":"ClusterIP"}` | ratel Service configuration (type, labels, annotations, load-balancer settings). |
| serviceAccount.annotations | object | `{}` | Annotations added to the ServiceAccount. |
| serviceAccount.automountServiceAccountToken | bool | `false` | Do not mount the API token; no dgraph workload calls the Kubernetes API. |
| serviceAccount.create | bool | `true` | Create the dgraph ServiceAccount. |
| serviceAccount.name | string | `""` | Name of the ServiceAccount; empty means use the chart fullname. |
| serviceMonitor | object | `{"enabled":false,"interval":"30s","labels":{},"path":"/debug/prometheus_metrics","scrapeTimeout":"10s"}` | Prometheus Operator ServiceMonitor (gated production add-on). |
| tracing.alpha.service | string | `"dgraph-sec.alpha"` | Trace service name reported for alpha. |
| tracing.enabled | bool | `false` | Enable OTEL trace export from alpha and zero. |
| tracing.endpoint | string | `"datadog-agent.datadog.svc.cluster.local:4318"` | OTLP/HTTP collector endpoint for traces (port 4318). |
| tracing.ratio | string | `"0.01"` | Trace sampling ratio (fraction of requests traced). |
| tracing.zero.service | string | `"dgraph-sec.zero"` | Trace service name reported for zero. |
| zero.alsologtostderr | bool | `false` | Also write zero logs to files under logDir (--alsologtostderr). |
| zero.antiAffinity | string | `"soft"` | Pod anti-affinity strength for zero (soft = best effort, hard = required). |
| zero.automountServiceAccountToken | bool | `false` | Do not mount the API token on zero pods; zero never calls the K8s API. |
| zero.configFile | object | `{}` | Config-file contents for zero (alternative to CLI flags). |
| zero.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"readOnlyRootFilesystem":false}` | Secure-by-default container securityContext for zero (drop ALL caps, no privilege escalation). |
| zero.customLivenessProbe | object | `{}` | Full custom liveness probe spec for zero (overrides livenessProbe). |
| zero.customReadinessProbe | object | `{}` | Full custom readiness probe spec for zero (overrides readinessProbe). |
| zero.customStartupProbe | object | `{}` | Full custom startup probe spec for zero (overrides startupProbe). |
| zero.envFrom | list | `[]` | Extra envFrom sources (configMaps/secrets) for the zero container. |
| zero.extraAnnotations | object | `{}` | Extra annotations on the zero StatefulSet pod template. |
| zero.extraEnvs | list | `[]` | Extra environment variables appended to the zero container. |
| zero.extraFlags | string | `""` | Extra command-line flags appended to dgraph-sec zero (logging fallthrough). |
| zero.livenessProbe | object | `{"enabled":true,"failureThreshold":6,"initialDelaySeconds":15,"path":"/health","periodSeconds":10,"port":6080,"successThreshold":1,"timeoutSeconds":5}` | Liveness probe for zero (against the 6080 /health endpoint). |
| zero.logDir | string | `""` | Directory for zero glog file output (--log_dir); needs a writable mount. |
| zero.logLevel | string | `"normal"` | Zero log verbosity: named level (normal|verbose|debug|trace) or a raw glog -v integer. |
| zero.logtostderr | bool | `true` | Send zero logs to stderr (--logtostderr). Keep true for Kubernetes log capture. |
| zero.metrics | object | `{"enabled":true}` | Toggle Prometheus metrics scrape annotations on zero. |
| zero.monitorLabel | string | `"zero-dgraph-io"` | Value of the "monitor" label on the zero Service for Prometheus discovery. |
| zero.name | string | `"zero"` | Component name for the zero (cluster coordinator) workload. |
| zero.nodeAffinity | object | `{}` | Node affinity rules for zero pod scheduling. |
| zero.nodeSelector | object | `{}` | Node selector for zero pod scheduling. |
| zero.pdb | object | `{"enabled":true,"minAvailable":2}` | PodDisruptionBudget protecting the zero Raft quorum. |
| zero.persistence | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"persistentVolumeClaimRetentionPolicy":{"whenDeleted":"Retain","whenScaled":"Retain"},"size":"32Gi"}` | Persistent volume claim template for zero data. |
| zero.persistence.persistentVolumeClaimRetentionPolicy | object | `{"whenDeleted":"Retain","whenScaled":"Retain"}` | StatefulSet PVC retention policy. whenDeleted applies on `helm uninstall`; whenScaled on replica reduction. Each "Retain" or "Delete". |
| zero.podAntiAffinitytopologyKey | string | `"kubernetes.io/hostname"` | Topology key for zero pod anti-affinity spreading. |
| zero.podLabels | object | `{}` | Extra pod labels on the zero StatefulSet. |
| zero.podManagementPolicy | string | `"Parallel"` | Pod management policy for the zero StatefulSet (OrderedReady or Parallel). |
| zero.readinessProbe | object | `{"enabled":true,"failureThreshold":6,"initialDelaySeconds":15,"path":"/state","periodSeconds":10,"port":6080,"successThreshold":1,"timeoutSeconds":5}` | Readiness probe for zero (against the 6080 /state endpoint). |
| zero.replicaCount | int | `3` | Number of zero coordinator pods (Raft membership). |
| zero.resources | object | `{"limits":{"memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | CPU/memory requests and limits for zero (light coordinator workload). |
| zero.securityContext | object | `{"enabled":true,"fsGroup":1001,"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001,"seccompProfile":{"type":"RuntimeDefault"}}` | Secure-by-default pod securityContext for zero (non-root, RuntimeDefault seccomp). |
| zero.service | object | `{"annotations":{},"externalTrafficPolicy":"","labels":{},"loadBalancerIP":"","loadBalancerSourceRanges":[],"publishNotReadyAddresses":true,"type":"ClusterIP"}` | zero Service configuration (type, labels, annotations, load-balancer settings). |
| zero.serviceHeadless | object | `{"labels":{}}` | Labels for the zero headless Service. |
| zero.shardReplicaCount | int | `3` | Per-group replication factor; keep this at or below alpha.replicaCount. |
| zero.startupProbe | object | `{"enabled":false,"failureThreshold":6,"path":"/health","periodSeconds":10,"port":6080,"successThreshold":1,"timeoutSeconds":5}` | Startup probe for zero (against the 6080 /health endpoint). |
| zero.terminationGracePeriodSeconds | int | `60` | Termination grace period (seconds) for zero pods. |
| zero.tls | object | `{"enabled":false,"files":{}}` | TLS configuration for zero (cert files generated by dgraph-sec cert). |
| zero.tolerations | list | `[]` | Tolerations for zero pod scheduling. |
| zero.updateStrategy | string | `"RollingUpdate"` | StatefulSet update strategy for zero (RollingUpdate or OnDelete). |
| zero.vmodule | string | `""` | Zero per-module glog verbosity (--vmodule); empty disables. |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Istari Digital Infrastructure Team | <infra@istaridigital.com> |  |

# Dgraph-sec

<<<<<<< HEAD
![Version: 0.6.0](https://img.shields.io/badge/Version-0.6.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.3.7-sec.0.2.2](https://img.shields.io/badge/AppVersion-v25.3.7--sec.0.2.2-informational?style=flat-square)
=======
![Version: 0.6.1](https://img.shields.io/badge/Version-0.6.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.3.6-sec.0.2.1](https://img.shields.io/badge/AppVersion-v25.3.6--sec.0.2.1-informational?style=flat-square)
>>>>>>> 210641c (docs(dgraph-sec): configuration & topology reference + backup S3 IAM permissions (DGR-256, DGR-252))

Dgraph-sec — hardened Dgraph database for Istari platform

**Homepage:** <https://dgraph.io/>

This chart packages **dgraph-sec** — a distributed graph database — for the Istari
platform. It deploys the two stateful Dgraph roles, **Zero** (cluster coordinator /
Raft membership) and **Alpha** (data + query serving), plus optional Ratel UI,
binary-backup CronJobs, Datadog autodiscovery, and OpenTelemetry tracing.

> [!IMPORTANT]
> The **`-sec`** suffix names the **dgraph-sec product** — the FIPS-hardened Dgraph
> build that runs inside the container — **not** the chart. The chart is named after
> the product it deploys. See [Security posture](#security-posture) for how the image
> is hardened and how the chart deploys it.

The chart began as a fork of the upstream Dgraph **Helm chart**, with Istari-specific
changes: secure-by-default pod and container security contexts, the dgraph-sec binary
and image, Datadog/OTEL wiring, a 3-tier service-naming convention, and gated
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
non-root pods, and PodDisruptionBudgets. Because ACL is disabled by default, no login
is required, so applications can connect immediately.

> [!WARNING]
> A default install is **convenient, not production-secure**. The pods are hardened
> (non-root, dropped capabilities, seccomp), but the data-path protections —
> authentication (ACL), TLS in transit, encryption at rest, and NetworkPolicy — are
> all **off** by default, so the database is unauthenticated, plaintext, and reachable
> by any pod in the cluster. Turn these on before putting real data behind it; see
> [Security posture](#security-posture).

Istari Digital deploys this chart with Terraform and sets
`fullnameOverride: dgraph-sec`, which is why the deployed objects are named
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

> [!TIP]
> For the default cluster topology, a grouped reference of the chart's key
> configuration values, and the per-environment overrides Istari Digital applies
> on its own infrastructure (dev, stage, demo), see
> [Configuration and topology](./docs/configuration-and-topology.md).

## Naming

Everything uses a single identity: **`dgraph-sec`** — the chart name, the Helm
template helpers (`dgraph-sec.*`), the `app.kubernetes.io/name` / `app` / `chart`
labels, the deployed object names, the Datadog `superservice`, and the OTEL tracing
service names. The Datadog/tracing identity follows the 3-tier
`superservice.subservice` convention (e.g. `dgraph-sec.alpha`, `dgraph-sec.zero`).

## Security posture

The `-sec` suffix names the **dgraph-sec product** — the FIPS-hardened Dgraph build
that runs inside the container — not the chart. The chart is simply named after the
product it deploys. Security therefore comes in two layers: the hardened **image**,
and the way this **chart** runs it.

### The image: FIPS-hardened Dgraph

The dgraph-sec image performs its cryptography through a FIPS 140-validated module
rather than Go's built-in crypto:

- It is compiled with the Microsoft Go FIPS toolchain and `GOEXPERIMENT=systemcrypto`
  (with `CGO_ENABLED=1`), which routes Go's `crypto/*` calls to the system OpenSSL
  FIPS provider instead of Go's native implementations.
- The binary defaults to `GODEBUG=fips140=on`, and the runtime sets it again. This is
  **fail-closed**: the process panics on startup if the validated FIPS provider is
  missing, so it can never silently fall back to non-validated crypto.
- It runs on Chainguard's `chainguard-base-fips` minimal base image, which ships the
  OpenSSL FIPS provider validated under **NIST CMVP certificate #5132**.
- The image's own default user is **non-root** (uid 65532).

### The chart: deploying that image securely

The chart defaults `image.*` to the hardened image and runs it under a restrictive
Kubernetes security posture. You get this with no configuration, on the Alpha, Zero,
and Ratel workloads:

- Pods run as a **non-root** user (`runAsNonRoot: true`, uid/gid 1001) under a
  `RuntimeDefault` seccomp profile.
- Containers **drop every Linux capability** and cannot escalate privileges.
  `readOnlyRootFilesystem` is left `false` because Dgraph writes scratch data outside
  its mounted data directory. Validate on a cluster before turning it on.
- `automountServiceAccountToken` is **off** on the long-running Dgraph workloads
  (Alpha, Zero, Ratel, and the backup CronJobs), because none of them call the
  Kubernetes API. The optional pre-upgrade hook Job is the one exception — it runs
  `kubectl`, so it mounts a token by design.
- PodDisruptionBudgets (`minAvailable: 2`) protect quorum during voluntary
  disruptions (node drains, autoscaler scale-downs) for a 3-node Raft group — Zero,
  and Alpha at its default 3 replicas. When you scale Alpha past 3 into multiple
  groups, raise `alpha.pdb.minAvailable`, since a flat `minAvailable: 2` across all
  Alpha pods could otherwise let a whole group be taken below quorum.

The chart never touches the image's FIPS environment, so `fips140=on` stays in effect
at runtime. One gap to know about: the backup CronJobs run the same image but set no
pod or container securityContext of their own (they only disable token automount), so
those pods fall back to the image's user and the cluster defaults rather than the
explicit non-root / seccomp / dropped-capabilities context the Alpha and Zero pods
receive.

### Production toggles you must enable

Four application-level protections stay **off** by default, because each one needs a
deliberate decision or some external material (a key, a certificate, a Secret). Turn
them on for a production posture:

- **ACL** adds authentication and authorization.
- **Encryption at rest** encrypts the on-disk data.
- **TLS in transit** encrypts client and cluster traffic.
- **NetworkPolicy** gates ingress to the Alpha and Zero pods: only in-chart dgraph
  pods may reach Zero, and only pods you mark with `clientPodLabels` may reach
  Alpha's client ports (8080/9080). Anything else needs `networkPolicy.extraIngress`.

```yaml
# values.yaml — production-posture toggles (each still needs its key/secret material)
alpha:
  acl:
    enabled: true       # authentication + authorization (provide an HMAC secret)
  encryption:
    enabled: true       # encryption at rest (provide an encryption key)
  tls:
    enabled: true       # provisions + mounts TLS cert material — see the TLS note below
zero:
  tls:
    enabled: true       # Zero needs TLS cert material too — see the TLS note below
networkPolicy:
  enabled: true         # gate ingress to the Alpha and Zero pods
  clientPodLabels:      # these pods may reach Alpha's client ports 8080/9080 (Zero stays internal)
    app.kubernetes.io/part-of: my-client-app
```

ACL and encryption each need key or Secret material; see `values.yaml` and the
post-install NOTES for the exact flags.

> [!IMPORTANT]
> **TLS in transit depends on the deployment mode.** Under a service mesh
> (`serviceMesh.enabled: true`, the default), the mesh encrypts traffic, so
> `alpha.tls.enabled` / `zero.tls.enabled` only create and mount the TLS Secret at
> `/dgraph/tls`. Without a mesh, set `serviceMesh.enabled: false` and enable TLS per
> tier (`alpha.tls.enabled` / `zero.tls.enabled: true`): for each tier with TLS on,
> the chart then synthesizes Dgraph's `--tls` superflag from the `*.tls` keys
> (`internalPort`, `clientName`, `clientAuthType`) and switches the probes to HTTPS —
> no `extraFlags` editing. See the chart docs, "Deploying without a service mesh."

## Backups & restore

Dgraph takes binary backups. Turn them on with `backups.full.enabled` and
`backups.incremental.enabled`, then point `backups.destination` at a file path, an
NFS mount, or an S3/MinIO bucket. The chart runs two CronJobs from there: one full
backup and one incremental, each on its own schedule.

Restoring is never automatic. It is a deliberate, operator-driven action, and the
step-by-step runbook lives in
[`scripts/README.md`](./scripts/README.md#restoring-from-a-binary-backup).

Each backup pod follows the Alpha it backs up. The CronJobs inherit
`alpha.nodeSelector` and `alpha.tolerations`, so a backup pod lands on the same node
group as Alpha, triggers the backup against `alpha-0`, and — for filesystem or NFS
destinations — shares Alpha's backup volume. Pin Alpha to a dedicated, tainted node
group and the backups follow it there. Leave Alpha scheduling unset and they
schedule anywhere.

```yaml
# values.yaml — daily full + hourly incremental backups to S3
backups:
  destination: s3://s3.us-west-2.amazonaws.com/my-dgraph-backups
  full:
    enabled: true
    schedule: "0 0 * * *"      # every day at midnight
  incremental:
    enabled: true
    schedule: "0 1-23 * * *"   # every hour except midnight
  admin:
    user: backup-admin                       # required once ACL is on
    existingSecret: dgraph-sec-backup-admin  # holds the password; keeps it out of values/git
```

### S3 permissions

When `backups.destination` is an `s3://` URI, the AWS credentials the backups use
must allow `s3:ListBucket` on the bucket and `s3:GetObject`, `s3:PutObject`,
`s3:DeleteObject`, and `s3:AbortMultipartUpload` on its objects.

`s3:DeleteObject` is not optional: S3 has no rename, so after every backup Dgraph
promotes `manifest_tmp.json` to `manifest.json` by copy-then-delete. Without it,
every backup reports `resolving backup failed because task failed` even though the
backup data and manifest uploaded; the detailed `AccessDenied` error appears only
in the Alpha leader's logs.

The backup task executes on the **Alpha leader**, not in the backup CronJob pod,
so the credentials must be available to the Alpha pods — grant them via the chart's
ServiceAccount (EKS Pod Identity / IRSA) or set `backups.keys.s3` — not just to
the backup Job pods.

> [!WARNING]
> Credentials (`backups.admin.password`, `backups.admin.auth_token`, ACL secrets) set
> inline in a values file are visible via `helm get values` and tend to leak into git.
> Prefer External Secrets Operator or Sealed Secrets. When ACL is enabled the chart
> **requires** `backups.admin.user` so backups can never silently fall back to the
> well-known `groot` superadmin.

## Monitoring

Out of the box, the Alpha and Zero pods carry `prometheus.io/*` scrape annotations
that point at Dgraph's metrics endpoint (`/debug/prometheus_metrics`). Any Prometheus
configured for annotation-based discovery picks them up with no extra setup.

The **Prometheus Operator** works differently — it discovers targets through
`ServiceMonitor` objects, not annotations. Set `serviceMonitor.enabled` to have the
chart create one, and `prometheusRule.enabled` to ship a set of default alerts.
Separately, `datadog.enabled` adds Datadog autodiscovery annotations and unified
service tags.

```yaml
# values.yaml — Prometheus Operator + Datadog
serviceMonitor:
  enabled: true
prometheusRule:
  enabled: true     # also ship the chart's default alert rules
datadog:
  enabled: true     # Datadog autodiscovery + unified service tags
```

## Logging

Dgraph logs through glog. Every role always writes `INFO`, `WARNING`, and `ERROR`
lines to stderr, where `kubectl logs` and the node log collector pick them up. You
cannot turn those severities off. Raising the log level only *adds* finer detail on
top of them, so a higher level shows you more but never hides a real warning or
error.

Set the level per role with `alpha.logLevel` and `zero.logLevel`, using either a
named level or the equivalent raw glog `-v` integer:

| Level | `-v` |
|-------|------|
| `normal` (default) | 0 |
| `verbose` | 1 |
| `debug` | 2 |
| `trace` | 3 |

A few finer controls sit alongside the level:

- **`vmodule`** narrows the extra verbosity to specific subsystems, e.g.
  `"server=3,raft=2"`, so you can dig into raft without flooding everything else.
- **`logtostderr`** should stay `true` on Kubernetes. Set it `false` without a
  writable `logDir` and a container restart loses its logs.
- **`extraFlags`** is the escape hatch for any glog flag the chart does not expose
  directly (`--stderrthreshold`, `--log_backtrace_at`, and the like). A `-v` placed
  here overrides `logLevel`.

```yaml
# values.yaml — verbose Alpha focused on the raft subsystem; quiet Zero
alpha:
  logLevel: verbose           # named level, or a raw integer like 1
  vmodule: "server=3,raft=2"  # extra detail for just these subsystems
  logtostderr: true           # keep true so kubectl logs sees everything
zero:
  logLevel: normal
```

## Tracing (OpenTelemetry)

Set `tracing.enabled` to export traces from Alpha and Zero. The chart assembles
Dgraph's `--trace` superflag from the `tracing` block and sends spans over OTLP/HTTP
to the collector you point it at:

| Value | Purpose |
|-------|---------|
| `tracing.endpoint` | OTLP/HTTP collector endpoint. Defaults to the Datadog agent on port 4318. |
| `tracing.ratio` | Fraction of requests sampled. Defaults to `0.01` (1%). |
| `tracing.alpha.service` / `tracing.zero.service` | Per-role service name reported to the collector (`dgraph-sec.alpha` / `dgraph-sec.zero`). |

```yaml
# values.yaml — export 1% of traces to an OTLP collector
tracing:
  enabled: true
  endpoint: "datadog-agent.datadog.svc.cluster.local:4318"
  ratio: "0.01"               # sample 1% of requests
  alpha:
    service: "dgraph-sec.alpha"
  zero:
    service: "dgraph-sec.zero"
```

On Istari Digital's own clusters, `tracing.enabled` tracks the Datadog operator, so
traces flow wherever the agent runs.

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
| alpha.initContainers | object | `{"init":{"command":["bash","-c","trap \"exit\" SIGINT SIGTERM\necho \"Write to /dgraph/doneinit when ready.\"\nuntil [ -f /dgraph/doneinit ]; do sleep 2; done\n"],"enabled":false,"env":[],"envFrom":[],"image":{"<<":{"debug":false,"pullPolicy":"IfNotPresent","registry":"istaridigital.jfrog.io","repository":"main-docker-local/dgraph-sec","tag":"v25.3.7-sec.0.2.2"}}}}` | Optional alpha pre-start init container (e.g. restore or bulk load before Alpha starts). |
| alpha.initContainers.init.image.<<.debug | bool | `false` | Enable verbose BASH/NAMI image debugging output. |
| alpha.initContainers.init.image.<<.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the dgraph-sec image. |
| alpha.initContainers.init.image.<<.registry | string | `"istaridigital.jfrog.io"` | Container registry hosting the dgraph-sec image. |
| alpha.initContainers.init.image.<<.repository | string | `"main-docker-local/dgraph-sec"` | Repository path for the hardened dgraph-sec image. |
| alpha.initContainers.init.image.<<.tag | string | `"v25.3.7-sec.0.2.2"` | dgraph-sec image tag (matches the chart appVersion). |
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
| alpha.tls | object | `{"clientAuthType":"","clientName":"","enabled":false,"files":{},"internalPort":true}` | TLS configuration for alpha (cert files generated by dgraph-sec cert). Under native TLS the sub-keys internalPort, clientName, and clientAuthType are read into Dgraph's TLS superflag (see their inline comments below). |
| alpha.tls.clientAuthType | string | `""` | Dgraph client-auth-type for the external ports (e.g. REQUIREANDVERIFY). Empty omits the field. |
| alpha.tolerations | list | `[]` | Tolerations for alpha pod scheduling. |
| alpha.updateStrategy | string | `"RollingUpdate"` | StatefulSet update strategy for alpha (RollingUpdate or OnDelete). |
| alpha.vmodule | string | `""` | Alpha per-module glog verbosity (--vmodule); empty disables. |
| backups.admin | object | `{"auth_token":"","existingSecret":"","password":"","passwordSecretKey":"backup_admin_password","tls_client":"","user":""}` | Backup admin credentials/token used to trigger backups when ACLs are enabled. |
| backups.destination | string | `"/dgraph/backups"` | Backup destination: a file path, s3://, or minio:// URI. |
| backups.full | object | `{"debug":false,"enabled":false,"restartPolicy":"Never","schedule":"0 0 * * *"}` | Full-backup CronJob (enable, schedule, restart policy). |
| backups.image | object | `{"<<":{"debug":false,"pullPolicy":"IfNotPresent","registry":"istaridigital.jfrog.io","repository":"main-docker-local/dgraph-sec","tag":"v25.3.7-sec.0.2.2"}}` | Image for backup CronJobs (defaults to the shared dgraph-sec image; needs curl). |
| backups.image.<<.debug | bool | `false` | Enable verbose BASH/NAMI image debugging output. |
| backups.image.<<.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the dgraph-sec image. |
| backups.image.<<.registry | string | `"istaridigital.jfrog.io"` | Container registry hosting the dgraph-sec image. |
| backups.image.<<.repository | string | `"main-docker-local/dgraph-sec"` | Repository path for the hardened dgraph-sec image. |
| backups.image.<<.tag | string | `"v25.3.7-sec.0.2.2"` | dgraph-sec image tag (matches the chart appVersion). |
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
| image.tag | string | `"v25.3.7-sec.0.2.2"` | dgraph-sec image tag (matches the chart appVersion). |
| imagePullSecrets | list | `[]` | Kubernetes-format image pull secrets applied to every Pod. Preferred over global.imagePullSecrets (legacy string list) and image.pullSecrets. |
| networkPolicy | object | `{"clientPodLabels":{},"enabled":false,"extraIngress":[]}` | NetworkPolicy gating ingress to alpha/zero ports (gated production add-on). |
| preUpgradeHook.enabled | bool | `true` | Run the v24-to-v25 StatefulSet selector migration Job on helm upgrade. |
| preUpgradeHook.image | object | `{"registry":"istaridigital.jfrog.io","repository":"remote-docker-chainguard/istaridigital.com/kubectl-iamguarded-fips","tag":"1.32"}` | kubectl image used by the pre-upgrade migration Job. |
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
| serviceMesh | object | `{"enabled":true}` | Service-mesh assumption that shapes encryption and identity. |
| serviceMonitor | object | `{"enabled":false,"interval":"30s","labels":{},"path":"/debug/prometheus_metrics","scrapeTimeout":"10s"}` | Prometheus Operator ServiceMonitor (gated production add-on). |
| tracing.alpha.service | string | `"dgraph-sec.alpha"` | Trace service name reported for alpha. |
| tracing.enabled | bool | `false` | Enable OTEL trace export from alpha and zero. |
| tracing.endpoint | string | `"datadog-agent.datadog.svc.cluster.local:4318"` | OTLP/HTTP collector endpoint for traces (port 4318). |
| tracing.ratio | string | `"0.01"` | Trace sampling ratio (fraction of requests traced). |
| tracing.zero.service | string | `"dgraph-sec.zero"` | Trace service name reported for zero. |
| validation | object | `{"adminPasswordSecretKey":"","adminUser":"groot","backupRoundtrip":false,"checkBackups":false,"cronjob":{"enabled":true},"enabled":false,"image":{},"job":{"backoffLimit":1,"enabled":true},"nodeSelector":{},"podAnnotations":{},"rbac":{"enabled":false},"retries":10,"retrySleep":12,"tolerations":[]}` | Post-install conformance validator (helm test + optional gating Job + manual CronJob). |
| validation.adminPasswordSecretKey | string | `""` | Secret key holding adminUser's password. Empty derives it (groot's key, else <adminUser>_password). |
| validation.adminUser | string | `"groot"` | Account the validator logs in as for auth-dependent checks. Defaults to the groot superadmin. |
| validation.backupRoundtrip | bool | `false` | Trigger a live backup round-trip to S3 (side-effecting, slow; reserved for future use). Default off. |
| validation.checkBackups | bool | `false` | Also assert the backup CronJobs exist with their expected schedules (requires rbac.enabled). |
| validation.cronjob.enabled | bool | `true` | Render the manual-trigger CronJob. |
| validation.enabled | bool | `false` | Master switch for all validator resources (ConfigMap, test Pod, Job, CronJob, RBAC). |
| validation.image | object | `{}` | Validator image. Empty (the default) reuses the deployed dgraph-sec image (which bundles bash, curl, jq) so the validator always matches the running version. Set all three fields below only to pin an explicit override. |
| validation.job | object | `{"backoffLimit":1,"enabled":true}` | Post-install/upgrade hook Job that gates the release on a passing validation. |
| validation.job.backoffLimit | int | `1` | Job backoffLimit (also used by the manual CronJob's jobTemplate). |
| validation.job.enabled | bool | `true` | Render the gating Job. |
| validation.nodeSelector | object | `{}` | nodeSelector for validator pods. Empty falls back to alpha.nodeSelector. |
| validation.podAnnotations | object | `{}` | Extra annotations for validator pods. |
| validation.rbac | object | `{"enabled":false}` | RBAC for the backup-CronJob check (the validator reads CronJobs via the Kubernetes API). |
| validation.rbac.enabled | bool | `false` | Create the validator ServiceAccount/Role/RoleBinding. Required by checkBackups. |
| validation.retries | int | `10` | Per-check retry attempts before failing. |
| validation.retrySleep | int | `12` | Seconds between retries. |
| validation.tolerations | list | `[]` | tolerations for validator pods. Empty falls back to alpha.tolerations. |
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
| zero.tls | object | `{"clientAuthType":"","clientName":"","enabled":false,"files":{},"internalPort":true}` | TLS configuration for zero (cert files generated by dgraph-sec cert). Under native TLS the sub-keys internalPort, clientName, and clientAuthType are read into Dgraph's TLS superflag (see their inline comments below). |
| zero.tls.clientAuthType | string | `""` | Dgraph client-auth-type for the external ports (e.g. REQUIREANDVERIFY). Empty omits the field. |
| zero.tolerations | list | `[]` | Tolerations for zero pod scheduling. |
| zero.updateStrategy | string | `"RollingUpdate"` | StatefulSet update strategy for zero (RollingUpdate or OnDelete). |
| zero.vmodule | string | `""` | Zero per-module glog verbosity (--vmodule); empty disables. |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Istari Digital Infrastructure Team | <infra@istaridigital.com> |  |

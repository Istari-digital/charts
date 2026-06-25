# Dgraph-sec

![Version: 0.6.1](https://img.shields.io/badge/Version-0.6.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.3.7-sec.0.2.2](https://img.shields.io/badge/AppVersion-v25.3.7--sec.0.2.2-informational?style=flat-square)

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

> [!IMPORTANT]
> Several configuration options change this — once enabled, other services in the
> cluster must be **explicitly allowed before they can connect** to Alpha:
> **NetworkPolicy** (`networkPolicy.enabled`) admits only pods carrying every label in
> `networkPolicy.clientPodLabels`; a **service mesh** requires the mesh
> `AuthorizationPolicy` to admit the client; **native TLS** (`alpha.tls.enabled` with no
> mesh) requires the client to trust the chart CA and, under `REQUIREANDVERIFY`, present
> a client certificate; and **ACL** (`alpha.acl.enabled`) requires the client to log in.
> See [Letting another in-cluster service connect](./docs/topology.md#letting-another-in-cluster-service-connect)
> for the exact steps per option.

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
> For a grouped reference of the chart's key configuration values, the
> per-environment overrides Istari Digital applies on its own infrastructure (dev,
> stage, demo), and the mesh-free deployment path, see [Configuration](#configuration)
> below. For the cluster topology those values produce and the network surface they
> expose, see [Topology and network surface](./docs/topology.md).

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
> no `extraFlags` editing. See [Deploying without a service mesh](#deploying-without-a-service-mesh).

## Backups & restore

Dgraph takes [binary backups](https://docs.dgraph.io/admin/admin-tasks/binary-backups). Turn them on with `backups.full.enabled` and
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

When ACL is on, the CronJob logs in to Alpha as `backups.admin.user` to trigger each
backup, so that user must exist and belong to the `guardians` group (the bootstrap's
`istari-admin` qualifies). Supply its password through a pre-created Secret, not inline:

```yaml
backups:
  admin:
    user: istari-admin
    existingSecret: dgraph-sec-acl-accounts   # the Secret holding the user's password
    passwordSecretKey: istari-admin_password  # the key within it
```

For a **MinIO / S3-compatible** endpoint, use a `minio://` destination and supply
`backups.keys.minio` (rendered as `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY`); set
`backups.minioSecure: false` for a plain-HTTP MinIO:

```yaml
backups:
  destination: minio://minio.my-namespace.svc:9000/dgraph-backups
  minioSecure: false
  keys:
    minio:
      access: <minio-access-key>
      secret: <minio-secret-key>
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

The chart does not provision the IAM role itself. In Istari's helm-stack the
`dgraph_sec_backups_pod_identity` module grants these actions to the chart
ServiceAccount via EKS Pod Identity; a standalone deployment must provision the
equivalent role (Pod Identity / IRSA) or supply `backups.keys.s3`. The requirement
is identical with or without a service mesh.

Backups also need network egress from the Alpha pods to the S3 endpoint (and to STS
when credentials come from IRSA). The chart's NetworkPolicy leaves egress
unrestricted for this reason, but a service mesh or a cluster-wide egress policy can
still block it; off a mesh, confirm cluster egress to S3/STS is permitted.

> [!WARNING]
> Credentials (`backups.admin.password`, `backups.admin.auth_token`, ACL secrets) set
> inline in a values file are visible via `helm get values` and tend to leak into git.
> Prefer External Secrets Operator or Sealed Secrets. When ACL is enabled the chart
> **requires** `backups.admin.user` so backups can never silently fall back to the
> well-known `groot` superadmin.

### Reaching Alpha: service mesh vs native TLS

The CronJob calls Alpha's `/admin` endpoint to start each backup, and how it connects
depends on the deployment mode. The chart wires this automatically — you do not set the
transport directly:

- **Under a service mesh** (`serviceMesh.enabled: true`, the default): the CronJob
  reaches Alpha over plain HTTP and the mesh sidecars encrypt the wire. No backup-side
  TLS configuration is needed, even if `*.tls.enabled` is set (those certificates are
  mounted but Dgraph stays plaintext on the pod).
- **Without a mesh, with native TLS** (`serviceMesh.enabled: false`,
  `alpha.tls.enabled: true`): the CronJob reaches Alpha over **HTTPS**, trusting the
  chart CA and targeting the alpha-0 headless FQDN that the server certificate's SANs
  cover. Under mutual TLS (`alpha.tls.clientAuthType: REQUIREANDVERIFY`) set
  `backups.admin.tls_client` to a client-certificate name so the CronJob presents one.
  The chart flips CACERT, HTTPS, and the FQDN on together through the `nativeTLS`
  predicate, so the ACL bootstrap Job and the backups stay consistent.
- **Without a mesh and without TLS**: the CronJob reaches Alpha over plain, unencrypted
  HTTP. Acceptable only for local/dev; NOTES warns about it.

In every mode the backup task itself runs on the **Alpha leader**, so the destination
credentials (or Pod Identity / IRSA) must reach the Alpha pods — see
[S3 permissions](#s3-permissions) above.

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

## Configuration

This section is the operator-facing guide to configuring the chart: the settable
values and their defaults grouped by component, the production-shaped overrides
Istari Digital applies on its own clusters (dev, stage, demo), and the deployment
path for clusters that run no service mesh. The topology and network surface those
values produce are documented separately in
[Topology and network surface](./docs/topology.md). For the exhaustive,
machine-generated list of every value, see the [Values](#values) section below;
helm-docs regenerates it from `values.yaml`, so it never drifts. The tables here are
a curated subset.

### Default configuration reference

The values below are the operator-relevant knobs and their chart defaults. Keys
are written in dotted form (`alpha.resources.requests.memory`). The full
enumeration lives in the [Values section](#values).

#### Image and chart-wide

| Key | Default | What it does |
|-----|---------|--------------|
| `image.registry` | `istaridigital.jfrog.io` | Registry hosting the hardened image. |
| `image.repository` | `main-docker-local/dgraph-sec` | Image repository path. |
| `image.tag` | `v25.3.7-sec.0.2.2` | Image tag (tracks `Chart.appVersion`). |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `preUpgradeHook.enabled` | `true` | Run the v24→v25 StatefulSet-selector migration Job on each upgrade. |
| `serviceAccount.create` | `true` | Create the dgraph ServiceAccount. |
| `serviceAccount.automountServiceAccountToken` | `false` | Token automount for the ServiceAccount object and the backup CronJob pods. Alpha, Zero, and Ratel each set their own `<component>.automountServiceAccountToken` (all `false`). No Dgraph workload calls the Kubernetes API; the pre-upgrade hook Job is the exception (its own ServiceAccount, runs `kubectl`). |
| `global.domain` | `cluster.local` | Cluster DNS domain used to build in-cluster hostnames. |

#### Zero (coordinator)

| Key | Default | What it does |
|-----|---------|--------------|
| `zero.replicaCount` | `3` | Number of Zero coordinator pods (Raft membership). |
| `zero.shardReplicaCount` | `3` | Per-group replication factor (`--replicas`); keep ≤ `alpha.replicaCount`. |
| `zero.antiAffinity` | `soft` | Pod anti-affinity strength (`soft` best-effort, `hard` required). |
| `zero.podManagementPolicy` | `Parallel` | StatefulSet pod management policy. |
| `zero.persistence.size` | `32Gi` | Per-pod data volume size. |
| `zero.persistence.persistentVolumeClaimRetentionPolicy` | `Retain` / `Retain` | PVC retention on uninstall / scale-down. |
| `zero.resources.requests` | `cpu: 100m`, `memory: 256Mi` | CPU/memory requests (light coordinator workload). |
| `zero.resources.limits` | `memory: 512Mi` | Memory limit (no CPU limit). |
| `zero.pdb` | `enabled: true`, `minAvailable: 2` | PodDisruptionBudget protecting the Zero quorum. |
| `zero.logLevel` | `normal` | Log verbosity: `normal`/`verbose`/`debug`/`trace` or a raw glog `-v`. |
| `zero.service.type` | `ClusterIP` | Zero Service type. |

#### Alpha (data and query)

| Key | Default | What it does |
|-----|---------|--------------|
| `alpha.replicaCount` | `3` | Number of Alpha data/query pods. |
| `alpha.antiAffinity` | `soft` | Pod anti-affinity strength. |
| `alpha.persistence.size` | `100Gi` | Per-pod data volume size. |
| `alpha.persistence.persistentVolumeClaimRetentionPolicy` | `Retain` / `Retain` | PVC retention on uninstall / scale-down. |
| `alpha.resources.requests` | `cpu: 250m`, `memory: 1Gi` | CPU/memory requests. |
| `alpha.resources.limits` | `memory: 2Gi` | Memory limit. **Right-size before production** — with a limit set, an over-budget query OOM-kills the Alpha pod; without one, a heavy query can exhaust the whole node. |
| `alpha.pdb` | `enabled: true`, `minAvailable: 2` | PodDisruptionBudget protecting the Alpha group. |
| `alpha.acl.enabled` | `false` | Access Control List (authentication). Off by default. |
| `alpha.encryption.enabled` | `false` | Encryption at rest. Off by default. |
| `alpha.tls.enabled` | `false` | Provisions and mounts the TLS cert Secret at `/dgraph/tls`. Under a service mesh the mesh encrypts, so that is all it does. With `serviceMesh.enabled: false`, the chart also synthesizes Dgraph's `--tls` flag from `alpha.tls.*` (and likewise for Zero). |
| `alpha.logLevel` | `normal` | Log verbosity (see Zero). |
| `alpha.service.type` | `ClusterIP` | Alpha Service type. |
| `alpha.ingress.enabled` / `alpha.ingress_grpc.enabled` | `false` | HTTP / gRPC Ingress for Alpha. |

#### Ratel, backups, and add-ons

| Key | Default | What it does |
|-----|---------|--------------|
| `ratel.enabled` | `false` | Deploy the Ratel debug UI. Never expose it publicly. |
| `backups.full.enabled` | `false` | Daily full binary backup CronJob. |
| `backups.incremental.enabled` | `false` | Hourly incremental backup CronJob. |
| `backups.destination` | `/dgraph/backups` | Backup target: a file path, `s3://`, or `minio://` URI. |
| `datadog.enabled` | `false` | Datadog autodiscovery annotations and unified service tags. |
| `tracing.enabled` | `false` | OpenTelemetry trace export (OTLP/HTTP) from Alpha and Zero. |
| `networkPolicy.enabled` | `false` | NetworkPolicy gating ingress to the Alpha/Zero ports. |
| `serviceMonitor.enabled` | `false` | Prometheus Operator ServiceMonitor. |
| `prometheusRule.enabled` | `false` | Prometheus Operator PrometheusRule with default alerts. |

### Example production configurations

Istari Digital deploys dgraph-sec with Terraform — the infrastructure-as-code it
uses to manage its own internal clusters — rather than with raw `helm install`.
That Terraform applies two layers of overrides on top of the chart defaults above:

- a **shared baseline** that every environment receives, and
- a small set of **per-environment values**.

The environments below — dev, stage, and demo — are Istari Digital's own internal
clusters, included here as reference examples of what a production-shaped
dgraph-sec deployment looks like. Each table shows the configuration that
environment deploys.

#### Shared baseline (all environments)

Every one of these environments hardens and right-sizes the chart the same way,
turning its small, generic defaults into a production cluster. The baseline does
five things:

- **Isolates the data tier.** Each Alpha runs on its own dedicated, tainted node,
  sized to hold an Alpha plus a co-located Zero (an `m6i.xlarge`-class node, roughly
  14.5Gi allocatable). The three Zeros land on three of those nodes — one-to-one in
  dev, three-of-six in stage/demo. **Hard** anti-affinity keeps any two Alphas off
  the same node.
- **Right-sizes resources.** Memory `request == limit` gives the data tier
  Guaranteed QoS, so the kernel never reclaims its memory under node pressure.
- **Turns on ACL.** Authentication is enabled, with a shared `istari-admin`
  superadmin account.
- **Uses fast storage.** Volumes come from the provisioned-IOPS `gp3` StorageClass.
- **Wires in backups and observability.** Scheduled **S3 backups** run as CronJobs,
  and both Datadog and OpenTelemetry are enabled.

The table lists every value the baseline changes from the chart default.

| Key | Chart default | Istari baseline | Why |
|-----|---------------|---------------------|-----|
| `fullnameOverride` | _(chart fullname)_ | `dgraph-sec` | Stable object names (`dgraph-sec-alpha`, `-zero`). |
| `preUpgradeHook.enabled` | `true` | `false` | Every cluster is past the v24→v25 migration; the hook is now pure overhead. |
| `zero.antiAffinity` / `alpha.antiAffinity` | `soft` | `hard` | One Alpha per node; never co-schedule a tier's pods. |
| `zero.nodeSelector` / `alpha.nodeSelector` | `{}` | `nodegroup-kind: dgraph` | Pin dgraph to its own node group. |
| `zero.tolerations` / `alpha.tolerations` | `[]` | a toleration for the `istari.k8s.io/role=dgraph:NoSchedule` taint | Admit dgraph to the tainted node group. Set as a list of toleration objects — see the YAML below. |
| `zero.resources.requests` | `cpu: 100m`, `memory: 256Mi` | `cpu: 500m`, `memory: 2Gi` | Size Zero for a production node. |
| `zero.resources.limits` | `memory: 512Mi` | `memory: 2Gi` | Guaranteed-QoS memory for Zero. |
| `alpha.resources.requests` | `cpu: 250m`, `memory: 1Gi` | `cpu: 2000m`, `memory: 10Gi` | Size Alpha to fill a dedicated node. |
| `alpha.resources.limits` | `memory: 2Gi` | `memory: 10Gi` | Guaranteed QoS; no overcommit on the data tier. |
| `alpha.extraFlags` | `""` | `--cache "size-mb=4096; percentage=40,40,20;"` | Cap off-heap posting-list and Badger caches. |
| `alpha.extraEnvs` | `[]` | env vars `GOGC=50` and `GOMEMLIMIT=8GiB` | GC hard before the kernel OOM-kills the pod. Set as a list of `{name, value}` objects — see the YAML below. |
| `alpha.acl.enabled` | `false` | `true` | Activate `--acl`, rotate `groot`, provision `istari-admin`. |
| `zero.persistence.storageClass` / `alpha.persistence.storageClass` | _(default provisioner)_ | `istari-gp3` | Provisioned-IOPS gp3 per Dgraph's SSD guidance. |
| `datadog.enabled` | `false` | `true` | Datadog autodiscovery and unified service tags. |
| `tracing.enabled` | `false` | `true` | OTLP/HTTP trace export to the Datadog agent. |
| `backups.full.enabled` / `backups.incremental.enabled` | `false` | `true` | Daily full + hourly incremental backups. |
| `backups.destination` | `/dgraph/backups` | `s3://s3.<region>.amazonaws.com/<bucket>` | Per-environment S3 bucket, accessed via Pod Identity. |
| `backups.admin.user` | `""` | `istari-admin` | Guardian account the backup Job logs in as (ACL on). |

As a single reference, the same baseline expressed as a values file looks like this.
It is a production-shaped starting point you can copy and adapt to your own node
group, StorageClass, and backup bucket.

```yaml
# values.yaml — production-shaped baseline (mirrors what Istari Digital deploys)
fullnameOverride: dgraph-sec

preUpgradeHook:
  enabled: false        # only needed for the one-time v24-to-v25 selector-label migration

zero:
  antiAffinity: hard
  nodeSelector:
    nodegroup-kind: dgraph
  tolerations:
    - key: istari.k8s.io/role
      operator: Equal
      value: dgraph
      effect: NoSchedule
  resources:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      memory: 2Gi       # request == limit → Guaranteed QoS
  persistence:
    storageClass: istari-gp3

alpha:
  antiAffinity: hard
  nodeSelector:
    nodegroup-kind: dgraph
  tolerations:
    - key: istari.k8s.io/role
      operator: Equal
      value: dgraph
      effect: NoSchedule
  acl:
    enabled: true
  extraFlags: '--cache "size-mb=4096; percentage=40,40,20;"'
  extraEnvs:
    - name: GOGC
      value: "50"
    - name: GOMEMLIMIT
      value: "8GiB"
  resources:
    requests:
      cpu: 2000m
      memory: 10Gi
    limits:
      memory: 10Gi      # request == limit → Guaranteed QoS
  persistence:
    storageClass: istari-gp3

datadog:
  enabled: true
tracing:
  enabled: true

backups:
  destination: s3://s3.<region>.amazonaws.com/<bucket>
  full:
    enabled: true
  incremental:
    enabled: true
  admin:
    user: istari-admin
```

Zero is fixed at **3 replicas with 32Gi** volumes across all environments; only
the Alpha tier varies, as the per-environment tables below show. Everything not
listed in those tables remains at the shared baseline.

#### dev — single group, smallest footprint

Internal development cluster. dev runs dgraph-sec at the baseline with **no
per-environment overrides**: 3 Alphas in a single replicated group on 3 dedicated
nodes, 3 Zeros, 100Gi per Alpha. It is the smallest production-shaped topology —
fully HA, fully hardened, sized for a development data set.

| Key | Baseline value | dev value |
|-----|----------------|-----------|
| _(none — deploys the shared baseline unchanged)_ | — | — |

#### stage and demo — two groups, larger volumes

Stage and demo share the same dgraph-sec configuration, so they are documented
together. Both scale the Alpha tier to **6 pods across 2 replicated groups**
(6 ÷ `zero.shardReplicaCount` 3), doubling write and storage capacity over dev, and
enlarge each Alpha volume to **250Gi** for a larger working set. That means 6
dedicated Alpha nodes (Zeros co-locate on 3 of them) instead of dev's 3.
Everything else matches the shared baseline.

| Key | Baseline value | stage / demo value |
|-----|----------------|--------------------|
| `alpha.replicaCount` | `3` | `6` |
| `alpha.persistence.size` | `100Gi` | `250Gi` |

As a values file, stage and demo are just the baseline above plus these two lines:

```yaml
# values.yaml — stage / demo deltas, layered on top of the baseline
alpha:
  replicaCount: 6        # 6 Alphas = 2 replicated groups (6 / zero.shardReplicaCount 3)
  persistence:
    size: 250Gi
```

### Deploying without a service mesh

Istari Digital shaped this chart around its own clusters, which run a
**strict-mTLS Istio mesh**. There, Envoy sidecars encrypt every connection
transparently, so Dgraph speaks plaintext and the chart leaves its native TLS off.
`serviceMesh.enabled: true` (the default) expresses that assumption. A few chart
details serve only the mesh: the Alpha headless Service publishes its client ports
(8080/9080) so the sidecar builds mTLS routes for them, and the ACL bootstrap Job
carries its own sidecar so Alpha does not reset its login.

Many clusters run no mesh. Set **`serviceMesh.enabled: false`** and the chart takes
on the two jobs the mesh did — **encrypting traffic** and **deciding which pods may
connect** — through Kubernetes-native mechanisms it already ships: it synthesizes
Dgraph's `--tls` flag, switches the health probes to HTTPS, and routes the ACL
bootstrap over TLS, while a standard `NetworkPolicy` segments the pods. The
mesh-specific details above stay inert without a sidecar, so they never get in your
way.

#### Encryption in transit: Dgraph-native TLS

A mesh hands every pod a cryptographic identity for free. Without one, Dgraph
terminates TLS itself, from certificates you generate and mount. Two steps enable
it; the chart builds the rest. For the underlying feature, see Dgraph's [TLS
configuration](https://docs.dgraph.io/admin/security/tls-configuration).

**1. Generate the certificates.** `scripts/make_tls_secrets.sh` wraps `dgraph-sec
cert` and writes a ready-to-apply values file. The certificates bind to the pods'
in-cluster DNS names, so the release name, `fullnameOverride`, namespace, domain,
and replica count must match the deployment exactly; otherwise the certificate SANs
will not cover the pod FQDNs and every TLS handshake fails at runtime.

```bash
# writes dgraph_tls/secrets.yaml containing alpha.tls.files and zero.tls.files
scripts/make_tls_secrets.sh \
  --release dgraph-sec \
  --fullname dgraph-sec \
  --namespace dgraph \
  --replicas 3 \
  --client dgraphuser \
  --zero
```

The script emits `ca.crt`, `node.crt`, `node.key`, and `client.dgraphuser.crt`/`.key`
per tier, base64-encoded under `alpha.tls.files` and `zero.tls.files`.

**2. Turn off the mesh assumption and configure TLS per tier.** Supply the generated
`secrets.yaml` with `-f` (or merge it), set `serviceMesh.enabled: false`, and enable
TLS on each tier. With `serviceMesh.enabled: false` and a tier's `tls.enabled: true`,
the chart mounts the certificates at **`/dgraph/tls`**, **synthesizes Dgraph's `--tls`
superflag** from the structured keys below, and switches that tier's probes to HTTPS:

```yaml
serviceMesh:
  enabled: false
alpha:
  tls:
    enabled: true
    files: { ... }            # from make_tls_secrets.sh
    internalPort: true        # encrypt inter-node traffic on 7080 (Raft/gossip)
    clientName: dgraphuser    # selects client.dgraphuser.crt/.key
    clientAuthType: REQUIREANDVERIFY
zero:
  tls:
    enabled: true
    files: { ... }
    internalPort: true
    clientName: dgraphuser
    clientAuthType: REQUIREANDVERIFY
```

You no longer hand-write `--tls` in `extraFlags`; the chart composes it from those
keys. Leaving a `--tls` in `extraFlags` while `serviceMesh.enabled: false` fails the
render, to stop a duplicate flag. `internalPort: true` with `clientName` encrypts
**inter-node** traffic — the Raft and gossip the mesh used to protect. The server
certificate encrypts the **client-facing** ports (8080/9080 on Alpha, 6080 on Zero).
Dgraph's
[TLS options](https://dgraph.io/docs/deploy/security/tls-configuration/) document
every field.

**What the mesh handled, now handled for you.** A sidecar gave every in-cluster
caller an identity automatically. Native TLS does not, so the chart provisions the
callers it controls:

- **Health probes.** Once TLS is on, Dgraph serves its HTTP endpoints — health checks
  included — over HTTPS. The chart switches its built-in probes to the HTTPS scheme
  for you. One case it cannot satisfy: `clientAuthType: REQUIREANDVERIFY` forces every
  caller, an `httpGet` probe included, to present a client certificate, which the
  kubelet's `httpGet` probe cannot do. The chart rejects that combination at render
  time; relax `clientAuthType` on the external ports (for example `VERIFYIFGIVEN`), or
  supply `customReadinessProbe`/`customLivenessProbe`/`customStartupProbe` (exec probes
  that present the client cert).
- **ACL bootstrap.** The ACL bootstrap Job logs in to Alpha's `/admin`. Under native
  TLS the chart mounts the CA and, when you set `clientName`, the client certificate,
  and points the reconciler at HTTPS — no manual step.
- **Backups.** The backup CronJobs also log in to `/admin`. Set
  `backups.admin.tls_client` to the client name you generated (`dgraphuser` above) so
  they present the same client certificate.

`clientAuthType` governs only the external ports. A value that requires no client
certificate keeps server-side encryption while sparing in-cluster callers;
`REQUIREANDVERIFY` is the strongest posture but forces every caller, probes included,
to present a valid client certificate.

**Why native TLS, not a mesh, on the `-sec` product.** dgraph-sec exists to route
cryptography through a FIPS 140-validated module
([NIST CMVP #5132](#security-posture)), fail-closed. A sidecar terminates
TLS in the proxy's own crypto stack, **outside** that validated boundary, which
undercuts the guarantee the product is built to make. Dgraph-native TLS keeps the
handshake inside the validated module, so for a FIPS posture it is the more
defensible choice, not merely the more portable one.

#### Network segmentation: Kubernetes NetworkPolicy

Istio's `AuthorizationPolicy` is one way to gate pod-to-pod traffic; the chart's
mesh-independent equivalent is a standard `NetworkPolicy`, off by default and enabled
with `networkPolicy.enabled`. Enabled, it allows intra-cluster dgraph traffic
(Alpha↔Zero and peer gossip), opens Alpha's client ports (8080/9080) only to pods
carrying every label in `networkPolicy.clientPodLabels`, and appends anything in
`networkPolicy.extraIngress`:

```yaml
networkPolicy:
  enabled: true
  clientPodLabels:
    app.kubernetes.io/part-of: my-client-app   # only these pods reach 8080/9080
```

**An enforcing CNI is required.** A `NetworkPolicy` takes effect only when the
cluster's CNI enforces it. Calico, Cilium, and Antrea do; the plain AWS VPC CNI does
not until you add its network-policy agent. On a CNI that ignores the object, the
policy applies cleanly yet isolates nothing — a false sense of security — which is
why the chart leaves it off until you enable it deliberately. For richer,
identity-aware rules, those same CNIs offer their own policy CRDs — Cilium's
`CiliumNetworkPolicy`, Calico's `GlobalNetworkPolicy` — as a superset of the standard
API.

**The policy restricts ingress only; egress is deliberately left open.** Replacing
mesh authorization with a `NetworkPolicy` segments who can *reach* the dgraph pods,
not where those pods may connect out — so enabling it does not break backups, OTEL
export, or NFS. If you add your own default-deny *egress* policy (a reasonable
instinct once there is no mesh), you must then explicitly allow the Alpha pods'
egress to the S3/STS endpoints, or backups fail with the misleading `resolving
backup failed` error even when the IAM grant is correct. See the
[S3 permissions](#s3-permissions) notes above.

#### Authentication: Dgraph ACL

Authentication needs no mesh. Enable `alpha.acl.enabled` for Dgraph's built-in [ACL](https://docs.dgraph.io/installation/configuration/enable-acl),
as the [shared baseline](#shared-baseline-all-environments) already does. Three
Kubernetes-native parts then stand in for the mesh: ACL proves who the caller is,
NetworkPolicy limits which pods may connect, and native TLS keeps the channel
private.

**Whitelist the cluster pod network.** Dgraph's ACL rejects admin logins from
source addresses it does not trust. Inside a mesh the sidecar makes every caller
look local, so this never surfaces. Without a mesh, the ACL bootstrap Job and the
backup CronJobs reach Alpha through its ClusterIP Service, whose source address the
CNI rewrites (SNAT) to a node IP the ACL does not trust; the login then fails with
`unauthorized ip address` and the post-install bootstrap hangs. Whitelist your
cluster's pod/node CIDR through Dgraph's `--security` flag so in-cluster callers are
trusted:

```yaml
alpha:
  extraFlags: '--security "whitelist=10.0.0.0/8;"'   # scope to your cluster's pod CIDR
```

Set the range to your cluster's actual pod network rather than `0.0.0.0/0`. This
applies to the backup CronJobs as well, since they authenticate to `/admin` the same
way.

#### Running locally on Docker Desktop

A complete, verified example of the mesh-free profile above is checked in at
[`example_values/docker-desktop.yaml`](./example_values/docker-desktop.yaml): one
Alpha and one Zero, ACL on, no persistence, shrunk resources, and the ACL whitelist
set so in-cluster login works. It is a local/dev profile — ephemeral data, broad
whitelist — not a production template. Run the commands below from the chart
directory.

1. Create the namespace:

   ```sh
   kubectl create namespace dgraph-sec-test
   ```

2. Create the image pull Secret from your Docker login (Docker must already be
   authenticated to the registry):

   ```sh
   kubectl -n dgraph-sec-test create secret generic jfrog-pull \
     --type=kubernetes.io/dockerconfigjson \
     --from-file=.dockerconfigjson="$HOME/.docker/config.json"
   ```

3. Create the ACL credentials Secret the bootstrap reads. The HMAC key must be at
   least 32 bytes:

   ```sh
   kubectl -n dgraph-sec-test create secret generic dgraph-sec-acl-local \
     --from-literal=hmac_secret_file="$(openssl rand -hex 16)" \
     --from-literal=groot_password="$(openssl rand -base64 18 | tr -d '/+=' | head -c 24)" \
     --from-literal=istari-admin_password="$(openssl rand -base64 18 | tr -d '/+=' | head -c 24)"
   ```

4. Install. `--wait` brings up Alpha and Zero, then the ACL bootstrap rotates groot
   and creates `istari-admin`, then the validator's post-install hook runs — a
   failed conformance check fails the install:

   ```sh
   helm install dgraph-sec . -n dgraph-sec-test -f example_values/docker-desktop.yaml --wait --timeout 12m
   ```

   > [!NOTE]
   > Use Helm **4.2.2+** or **3.x**. Helm **4.2.1** has a regression where waits stall
   > before the post-install hooks run, so on 4.2.1 both this `--wait` install and the
   > `helm test` in the next step hang. `brew upgrade helm` (or any Helm 3.x) resolves it.

5. Run the conformance validator on demand:

   ```sh
   helm test dgraph-sec -n dgraph-sec-test --logs
   ```

   It reports `dgraph-sec validation: PASS` with a `PASS` line for health,
   admin-login, ACL enforcement, membership, an authenticated query, and per-user
   login.

6. Tear down:

   ```sh
   helm uninstall dgraph-sec -n dgraph-sec-test
   kubectl delete namespace dgraph-sec-test
   ```

## Further reference

This chart wires up dgraph-sec; the upstream Dgraph documentation explains each
feature it configures in depth. The most relevant deep dives:

- **Authentication (ACL)** — [Access Control Lists](https://docs.dgraph.io/installation/configuration/enable-acl) and the [`dgraph acl` CLI](https://docs.dgraph.io/cli/acl).
- **TLS / mTLS in transit** — [TLS configuration](https://docs.dgraph.io/admin/security/tls-configuration); securing the admin endpoint with an [auth token](https://docs.dgraph.io/admin/security/admin-endpoint-security).
- **Encryption at rest** — [Encryption at rest](https://docs.dgraph.io/installation/configuration/encryption-at-rest).
- **Binary backups & restore** — [Binary backups](https://docs.dgraph.io/admin/admin-tasks/binary-backups) and [`dgraph restore`](https://docs.dgraph.io/cli/restore).
- **The database itself** — [What is Dgraph?](https://docs.dgraph.io/dgraph-overview).

These pages describe the Dgraph features; this chart's values turn them on and wire
them together — see [Configuration](#configuration) and the Backups & restore section above.

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

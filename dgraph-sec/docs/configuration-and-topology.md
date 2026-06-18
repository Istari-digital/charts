# Dgraph-sec configuration and topology

This page describes, in one place, what the `dgraph-sec` chart deploys and how
Istari tunes it per environment. It is written for an operator who is about to
run, size, or review a dgraph-sec cluster.

It covers three layers, from most generic to most specific:

1. **[Default cluster topology](#default-cluster-topology)** — the cluster the
   unmodified chart produces.
2. **[Default configuration reference](#default-configuration-reference)** — the
   key settable values and their defaults, grouped by component.
3. **[Example production configurations](#example-production-configurations)** —
   the overrides Istari's [helm-stack][helm-stack] applies, both the shared
   baseline and the per-environment deltas (dev, stage, demo).

For the exhaustive, machine-generated list of every value, see the **Values**
section of the [chart README](../README.md#values); helm-docs regenerates it
from `values.yaml`, so it never drifts. The tables here are a curated,
operator-facing subset.

[helm-stack]: https://github.com/Istari-digital/helm-stack

---

## Default cluster topology

`helm install dgraph-sec main-helm-local/dgraph-sec` with no overrides brings up
a small but genuinely highly-available cluster:

| Role | Kind | Default replicas | Purpose |
|------|------|------------------|---------|
| **Zero** | StatefulSet | 3 | Cluster coordinator — Raft membership, tablet/shard assignment, timestamp oracle. |
| **Alpha** | StatefulSet | 3 | Stores predicates and posting lists; serves DQL/GraphQL queries (Raft per group). |
| **Ratel** | Deployment | 1 (disabled) | Debug-grade web UI. Off by default. |
| **Backups** | CronJob (×2) | (disabled) | Two CronJobs — full + incremental binary backups to filesystem, NFS, S3, or MinIO. |

**Replication and sharding.** The three Alphas form a single replicated group:
`alpha.replicaCount: 3` divided by `zero.shardReplicaCount: 3` (Zero's
`--replicas` flag) yields one group whose data is replicated across all three
pods. Adding capacity means adding groups — raise `alpha.replicaCount` in
multiples of `zero.shardReplicaCount` (6 Alphas make 2 groups), rather than
enlarging pods. Keep `zero.shardReplicaCount` at or below `alpha.replicaCount`.

**Scheduling.** Both tiers default to **soft** pod anti-affinity keyed on
`kubernetes.io/hostname`, so Kubernetes spreads pods across nodes on a
best-effort basis but still schedules them when nodes are scarce. The chart sets
no `nodeSelector` or `tolerations` by default, so pods land on any schedulable
node.

**Availability.** A PodDisruptionBudget (`minAvailable: 2`) guards each tier, so
a voluntary disruption — a node drain or an autoscaler scale-down — can never
take two Zeros or two Alphas at once and drop a Raft group below quorum.

**Storage.** Persistence is on for both tiers: 32Gi per Zero, 100Gi per Alpha,
`ReadWriteOnce`, provisioned by the cluster's default StorageClass. The PVC
retention policy is `Retain` on both uninstall and scale-down, so deleting the
release or shrinking the cluster never reclaims data volumes.

**Networking.** Every Service is `ClusterIP`; the StatefulSets also publish
headless Services with `publishNotReadyAddresses: true` so peers can find each
other before they are Ready. Ingress and NetworkPolicy are off by default.

**Security posture.** This is the `-sec` fork, so secure defaults are baked in.
The **Alpha, Zero, and Ratel** pods run non-root (uid/gid 1001) with a
`RuntimeDefault` seccomp profile, and their containers drop all Linux
capabilities and forbid privilege escalation. No workload mounts a ServiceAccount
token. The backup CronJobs set no explicit securityContext of their own — they
disable token automount but otherwise inherit the image's user and the cluster's
defaults. Authentication (ACL), encryption at rest, and TLS in transit ship
**off** — enable them for a production posture.

---

## Default configuration reference

The values below are the operator-relevant knobs and their chart defaults. Keys
are written in dotted form (`alpha.resources.requests.memory`). The full
enumeration lives in the [chart README Values section](../README.md#values).

### Image and chart-wide

| Key | Default | What it does |
|-----|---------|--------------|
| `image.registry` | `istaridigital.jfrog.io` | Registry hosting the hardened image. |
| `image.repository` | `main-docker-local/dgraph-sec` | Image repository path. |
| `image.tag` | `v25.3.4-sec.0.1.0` | Image tag (tracks `Chart.appVersion`). |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `preUpgradeHook.enabled` | `true` | Run the v24→v25 StatefulSet-selector migration Job on each upgrade. |
| `serviceAccount.create` | `true` | Create the dgraph ServiceAccount. |
| `serviceAccount.automountServiceAccountToken` | `false` | Withhold the API token; no workload calls the Kubernetes API. |
| `global.domain` | `cluster.local` | Cluster DNS domain used to build in-cluster hostnames. |

### Zero (coordinator)

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

### Alpha (data and query)

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
| `alpha.tls.enabled` | `false` | TLS in transit. Off by default. |
| `alpha.logLevel` | `normal` | Log verbosity (see Zero). |
| `alpha.service.type` | `ClusterIP` | Alpha Service type. |
| `alpha.ingress.enabled` / `alpha.ingress_grpc.enabled` | `false` | HTTP / gRPC Ingress for Alpha. |

### Ratel, backups, and add-ons

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

---

## Example production configurations

Istari deploys dgraph-sec through Terraform in [helm-stack][helm-stack]
(`istari-k8s-core/dgraph-sec.tf`), not with raw `helm install`. The Terraform
applies two layers of overrides on top of the chart defaults above:

- a **shared baseline** that every environment receives, and
- a small set of **per-environment variables** (`environments/<env>/config.tfvars`).

The environments below — dev, stage, and demo — are reference examples of what a
production-shaped dgraph-sec deployment looks like. The configuration shown is
what each environment deploys when dgraph-sec is enabled there, independent of
whether the `dgraph_sec_enabled` toggle is currently on.

### Shared baseline (all environments)

Every Istari environment hardens and right-sizes the chart the same way. The
baseline turns the chart's small, generic defaults into a production cluster:
one Alpha per **dedicated, tainted node** (the module targets an `m6i.xlarge`-class
node, ~14.5Gi allocatable, with a Zero co-located), **hard** anti-affinity so no
two Alphas share a node, **ACL on** with a shared `istari-admin` superadmin,
memory `request == limit` for Guaranteed QoS on the data tier, `gp3` storage, and
scheduled **S3 backups** with Datadog and OpenTelemetry wired in.

| Key | Chart default | helm-stack baseline | Why |
|-----|---------------|---------------------|-----|
| `fullnameOverride` | _(chart fullname)_ | `dgraph-sec` | Stable object names (`dgraph-sec-alpha`, `-zero`). |
| `preUpgradeHook.enabled` | `true` | `false` | Every cluster is past the v24→v25 migration; the hook is now pure overhead. |
| `zero.antiAffinity` / `alpha.antiAffinity` | `soft` | `hard` | One Alpha per node; never co-schedule a tier's pods. |
| `zero.nodeSelector` / `alpha.nodeSelector` | `{}` | `nodegroup-kind: dgraph` | Pin dgraph to its own node group. |
| `zero.tolerations` / `alpha.tolerations` | `[]` | `istari.k8s.io/role=dgraph:NoSchedule` | Admit dgraph to the tainted node group. |
| `zero.resources.requests` | `cpu: 100m`, `memory: 256Mi` | `cpu: 500m`, `memory: 2Gi` | Size Zero for a production node. |
| `zero.resources.limits` | `memory: 512Mi` | `memory: 2Gi` | Guaranteed-QoS memory for Zero. |
| `alpha.resources.requests` | `cpu: 250m`, `memory: 1Gi` | `cpu: 2000m`, `memory: 10Gi` | Size Alpha to fill a dedicated node. |
| `alpha.resources.limits` | `memory: 2Gi` | `memory: 10Gi` | Guaranteed QoS; no overcommit on the data tier. |
| `alpha.extraFlags` | `""` | `--cache "size-mb=4096; percentage=40,40,20;"` | Cap off-heap posting-list and Badger caches. |
| `alpha.extraEnvs` | `[]` | `GOGC=50`, `GOMEMLIMIT=8GiB` | GC hard before the kernel OOM-kills the pod. |
| `alpha.acl.enabled` | `false` | `true` | Activate `--acl`, rotate `groot`, provision `istari-admin`. |
| `zero.persistence.storageClass` / `alpha.persistence.storageClass` | _(default provisioner)_ | `istari-gp3` | Provisioned-IOPS gp3 per Dgraph's SSD guidance. |
| `datadog.enabled` | `false` | `true` | Datadog autodiscovery and unified service tags. |
| `tracing.enabled` | `false` | `true` | OTLP/HTTP trace export to the Datadog agent. |
| `backups.full.enabled` / `backups.incremental.enabled` | `false` | `true` | Daily full + hourly incremental backups. |
| `backups.destination` | `/dgraph/backups` | `s3://s3.<region>.amazonaws.com/<bucket>` | Per-environment S3 bucket, accessed via Pod Identity. |
| `backups.admin.user` | `""` | `istari-admin` | Guardian account the backup Job logs in as (ACL on). |

Zero is fixed at **3 replicas with 32Gi** volumes across all environments; only
the Alpha tier varies, as the per-environment tables below show. Everything not
listed in those tables remains at the shared baseline.

### dev — single group, smallest footprint

Internal development cluster. dev runs dgraph-sec at the baseline with **no
per-environment overrides**: 3 Alphas in a single replicated group on 3 dedicated
nodes, 3 Zeros, 100Gi per Alpha. It is the smallest production-shaped topology —
fully HA, fully hardened, sized for a development data set.

| Key | Baseline value | dev value |
|-----|----------------|-----------|
| _(none — deploys the shared baseline unchanged)_ | — | — |

### stage and demo — two groups, larger volumes

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

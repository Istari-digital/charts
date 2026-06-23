# Dgraph-sec configuration and topology

This page describes, in one place, what the `dgraph-sec` chart deploys and how
Istari Digital tunes it across its own environments. It is written for an
operator who is about to run, size, or review a dgraph-sec cluster.

It covers three layers, from most generic to most specific:

1. **[Default cluster topology](#default-cluster-topology)** — the cluster the
   unmodified chart produces.
2. **[Default configuration reference](#default-configuration-reference)** — the
   key settable values and their defaults, grouped by component.
3. **[Example production configurations](#example-production-configurations)** —
   the overrides Istari Digital applies when it deploys this chart on its own
   infrastructure, both the shared baseline and the per-environment deltas (dev,
   stage, demo).

A closing section, **[Deploying without a service mesh](#deploying-without-a-service-mesh)**,
shows how to reach a production security posture on clusters that run no mesh. Set
`serviceMesh.enabled: false` and the chart wires Dgraph-native TLS in place of the
mesh's sidecar mTLS, switches the probes to HTTPS, and routes the ACL bootstrap over
TLS — work you would otherwise do by hand.

For the exhaustive, machine-generated list of every value, see the **Values**
section of the [chart README](../README.md#values); helm-docs regenerates it
from `values.yaml`, so it never drifts. The tables here are a curated,
operator-facing subset.

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

**Replication and sharding.** The three Alphas form a single replicated group. The
number of groups is `alpha.replicaCount` divided by `zero.shardReplicaCount` (Zero's
`--replicas` flag). Here that is 3 ÷ 3 = one group, with the data replicated across
all three Alpha pods.

To add capacity, add groups rather than enlarging individual pods: raise
`alpha.replicaCount` in multiples of `zero.shardReplicaCount`. Six Alphas, for
example, make two groups. Always keep `zero.shardReplicaCount` at or below
`alpha.replicaCount`, or the extra replication factor has no pods to land on.

**Scheduling.** Both tiers default to **soft** pod anti-affinity keyed on
`kubernetes.io/hostname`, so Kubernetes spreads pods across nodes on a
best-effort basis but still schedules them when nodes are scarce. The chart sets
no `nodeSelector` or `tolerations` by default, so pods land on any schedulable
node.

**Availability.** A PodDisruptionBudget (`minAvailable: 2`) guards each tier
against voluntary disruptions such as a node drain or an autoscaler scale-down. For
a 3-node Raft group — Zero, and Alpha at its default 3 replicas — that keeps quorum
intact. When Alpha scales past 3 into multiple groups, raise `alpha.pdb.minAvailable`
accordingly, because a flat `minAvailable: 2` across all Alpha pods could otherwise
let a whole group drop below quorum.

**Storage.** Persistence is on for both tiers: 32Gi per Zero, 100Gi per Alpha,
`ReadWriteOnce`, provisioned by the cluster's default StorageClass. The PVC
retention policy is `Retain` on both uninstall and scale-down, so deleting the
release or shrinking the cluster never reclaims data volumes.

**Networking.** Every Service is `ClusterIP`; the StatefulSets also publish
headless Services with `publishNotReadyAddresses: true` so peers can find each
other before they are Ready. Ingress and NetworkPolicy are off by default.

**Security posture.** The `-sec` suffix names the **dgraph-sec product** — the
FIPS-hardened Dgraph build that runs in the container — not the chart. That image
routes its cryptography through a FIPS 140-validated OpenSSL module (NIST CMVP
#5132) on a Chainguard `chainguard-base-fips` base, and fails closed if the
provider is missing. The chart then deploys it under a restrictive Kubernetes
posture: the **Alpha, Zero, and Ratel** pods run non-root (uid/gid 1001) with a
`RuntimeDefault` seccomp profile, and their containers drop all Linux capabilities
and forbid privilege escalation. Those workloads and the backup CronJobs all leave
the ServiceAccount token unmounted; only the optional pre-upgrade hook Job mounts
one, because it runs `kubectl`. The backup CronJobs are the exception to the
securityContext hardening — they set none of their own and fall back to the image's
user and the cluster defaults.

The application-layer controls — authentication (ACL), encryption at rest, and
NetworkPolicy — ship **off** and must be enabled for a production posture. TLS in
transit is off as well, and it is **not** a single toggle: `*.tls.enabled` only
provisions and mounts the certificate Secret, so encrypting traffic also requires
passing Dgraph's `--tls` flags through `extraFlags` (or a `configFile`) on both
Alpha and Zero. See the chart README's
[Security posture](../README.md#security-posture) for the full FIPS and deployment
detail.

For reference, here are the default values that produce the topology described
above. You get this with no overrides at all; the snippet is a convenient starting
point to copy and adjust.

```yaml
# values.yaml — the defaults behind the topology above (shown for reference; no overrides needed)
zero:
  replicaCount: 3        # 3-node Raft coordinator
  shardReplicaCount: 3   # per-group replication factor (Zero's --replicas)
  antiAffinity: soft     # best-effort spread across nodes
  persistence:
    enabled: true
    size: 32Gi
  pdb:
    enabled: true
    minAvailable: 2      # keep quorum through a voluntary disruption

alpha:
  replicaCount: 3        # 3 Alphas = one replicated group (alpha.replicaCount / zero.shardReplicaCount)
  antiAffinity: soft
  persistence:
    enabled: true
    size: 100Gi
  pdb:
    enabled: true
    minAvailable: 2

ratel:
  enabled: false         # debug UI off by default
```

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
| `serviceAccount.automountServiceAccountToken` | `false` | Token automount for the ServiceAccount object and the backup CronJob pods. Alpha, Zero, and Ratel each set their own `<component>.automountServiceAccountToken` (all `false`). No Dgraph workload calls the Kubernetes API; the pre-upgrade hook Job is the exception (its own ServiceAccount, runs `kubectl`). |
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
| `alpha.tls.enabled` | `false` | Provisions and mounts the TLS cert Secret only — off by default. **Not** sufficient to enable TLS on its own: also pass Dgraph's `--tls` flags via `alpha.extraFlags`/`configFile` (and likewise for Zero). |
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

Istari Digital deploys dgraph-sec with Terraform — the infrastructure-as-code it
uses to manage its own internal clusters — rather than with raw `helm install`.
That Terraform applies two layers of overrides on top of the chart defaults above:

- a **shared baseline** that every environment receives, and
- a small set of **per-environment values**.

The environments below — dev, stage, and demo — are Istari Digital's own internal
clusters, included here as reference examples of what a production-shaped
dgraph-sec deployment looks like. Each table shows the configuration that
environment deploys.

### Shared baseline (all environments)

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

As a values file, stage and demo are just the baseline above plus these two lines:

```yaml
# values.yaml — stage / demo deltas, layered on top of the baseline
alpha:
  replicaCount: 6        # 6 Alphas = 2 replicated groups (6 / zero.shardReplicaCount 3)
  persistence:
    size: 250Gi
```

---

## Deploying without a service mesh

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

### Encryption in transit: Dgraph-native TLS

A mesh hands every pod a cryptographic identity for free. Without one, Dgraph
terminates TLS itself, from certificates you generate and mount. Two steps enable
it; the chart builds the rest.

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
  for you. One case still needs your attention: `clientAuthType: REQUIREANDVERIFY`
  forces every caller, an `httpGet` probe included, to present a client certificate,
  which an `httpGet` probe cannot do. Relax `clientAuthType` on the external ports, or
  supply `customReadinessProbe`/`customLivenessProbe`/`customStartupProbe`, if you
  depend on the built-in probes.
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
([NIST CMVP #5132](../README.md#security-posture)), fail-closed. A sidecar terminates
TLS in the proxy's own crypto stack, **outside** that validated boundary, which
undercuts the guarantee the product is built to make. Dgraph-native TLS keeps the
handshake inside the validated module, so for a FIPS posture it is the more
defensible choice, not merely the more portable one.

### Network segmentation: Kubernetes NetworkPolicy

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

### Authentication: Dgraph ACL

Authentication needs no mesh. Enable `alpha.acl.enabled` for Dgraph's built-in ACL,
as the [shared baseline](#shared-baseline-all-environments) already does. Three
Kubernetes-native parts then stand in for the mesh: ACL proves who the caller is,
NetworkPolicy limits which pods may connect, and native TLS keeps the channel
private.

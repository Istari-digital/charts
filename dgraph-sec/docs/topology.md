# Dgraph-sec topology and network surface

This page describes the cluster the `dgraph-sec` chart deploys and the network it
exposes. It is written for an operator who is about to run, size, or review a
dgraph-sec cluster.

It covers two layers:

1. **[Default cluster topology](#default-cluster-topology)** — the cluster the
   unmodified chart produces: roles, replicas, replication, scheduling,
   availability, storage, and security posture.
2. **[Network surface](#network-surface-ports-exposure-and-client-access)** — the
   ports the chart opens, what leaves the cluster, the transport and authentication
   on each port, and how an in-cluster client connects.

Settable values, production-shaped examples, and the mesh-free deployment path now
live in the chart README's [Configuration](../README.md#configuration) section. For
the exhaustive, machine-generated list of every value, see the **Values** section of
the [chart README](../README.md#values); helm-docs regenerates it from `values.yaml`,
so it never drifts. The tables here are a curated, operator-facing subset.

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
transit is off as well, and how you turn it on depends on the deployment mode. Under
a service mesh (`serviceMesh.enabled: true`, the default), the mesh encrypts traffic
and `*.tls.enabled` only provisions and mounts the certificate Secret. Without a mesh
(`serviceMesh.enabled: false`), the chart synthesizes Dgraph's `--tls` flag from the
`*.tls` keys and switches probes to HTTPS — see
[Deploying without a service mesh](../README.md#deploying-without-a-service-mesh). See
the chart README's [Security posture](../README.md#security-posture) for the full FIPS
and deployment detail.

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

## Network surface: ports, exposure, and client access

This section enumerates every port the chart opens, whether it leaves the cluster,
and the transport and authentication on it. All three vary with independent toggles:
the deployment mode (`serviceMesh.enabled`), transport TLS (`*.tls.enabled`, wired
only off-mesh), and authentication (`alpha.acl.enabled`). The defaults are secure
against *external* exposure — every Service is `ClusterIP`, and Ingress and
NetworkPolicy are off — but not against unauthenticated *in-cluster* access until you
enable ACL and NetworkPolicy.

### Ports at a glance

| Port | Component | Name | Protocol | Reachable by default | Purpose |
|------|-----------|------|----------|----------------------|---------|
| 8080 | Alpha | `http-alpha` | HTTP(S) | in-cluster (ClusterIP) | Client API: GraphQL/DQL query + mutation, `/admin`, `/alter`, `/health`, `/state`. |
| 9080 | Alpha | `grpc-alpha` | gRPC | in-cluster (ClusterIP) | Client API over gRPC (the native Dgraph clients). |
| 7080 | Alpha | `grpc-alpha-int` | gRPC | intra-cluster only (headless Service) | Inter-node Alpha↔Alpha / Alpha↔Zero traffic. Never a client port. |
| 5080 | Zero | `grpc-zero` | gRPC | in-cluster (ClusterIP) | Internal: Alphas connect here to join the cluster. Not a client port. |
| 6080 | Zero | `http-zero` | HTTP(S) | in-cluster (ClusterIP) | Zero admin: `/state`, `/removeNode`, `/moveTablet`. **No ACL — unauthenticated.** |
| 80 → 8000 | Ratel | `http-ratel` | HTTP | only if `ratel.enabled` | Debug web UI; a browser client of Alpha, holds no data. Off by default. |

Only Alpha's `8080`/`9080` are client ports. The internal ports (`7080`, `5080`) and
Zero's admin (`6080`) carry cluster-control traffic and must never be exposed
externally or opened to client pods.

### What is exposed externally

**Nothing, by default.** Every Service is `ClusterIP`, and `alpha.ingress.enabled`,
`alpha.ingress_grpc.enabled`, and `global.ingress.enabled` are all `false`, so no port
leaves the cluster. External exposure is opt-in, by one of two mechanisms:

1. **Service type** — set `alpha.service.type` (or `zero` / `ratel`) to `LoadBalancer`
   or `NodePort` to publish that Service's ports (`8080`/`9080` for Alpha) at the cloud
   load balancer or node. Restrict the source with `alpha.service.loadBalancerSourceRanges`
   and preserve the client IP with `externalTrafficPolicy: Local`.
2. **Ingress** — set `alpha.ingress.enabled: true` (HTTP → `8080`) and/or
   `alpha.ingress_grpc.enabled: true` (gRPC → `9080`), each with `ingressClassName`,
   `hostname`, `annotations`, and a `tls:` block (`hosts` + `secretName`) that terminates
   TLS at the ingress. Requires an ingress controller.

Transport and auth on an exposed port follow the same rules as in-cluster (below). Two
cautions: never expose Zero's `6080` (unauthenticated admin) or the internal
`5080`/`7080`; and do not expose Alpha externally with ACL off, since `/alter` and
`/admin` are then open to anyone who reaches the port.

### Transport and authentication per mode

Transport on the HTTP/gRPC ports depends on the deployment mode; authentication on
Alpha's client API depends on ACL:

| Mode | On-the-wire transport | A client must |
|------|----------------------|---------------|
| **Service mesh** (`serviceMesh.enabled: true`, default) | Dgraph speaks **plaintext** on the pod; the Istio sidecars supply mTLS between meshed pods. `*.tls.enabled` only provisions and mounts the cert Secret. | be in the mesh (carry a sidecar) so its traffic is mTLS, and satisfy the mesh `AuthorizationPolicy` — owned by the platform mesh; the chart ships no Istio CRDs. |
| **No mesh + native TLS** (`serviceMesh.enabled: false`, `*.tls.enabled: true`) | Dgraph speaks **TLS** directly — HTTPS on `8080`, TLS gRPC on `9080` — from the synthesized `--tls`. With `tls.clientAuthType: REQUIREANDVERIFY` it is **mutual TLS**. | trust the chart CA, connect over TLS, and present a client certificate when `clientAuthType` requires one. |
| **No mesh, no TLS** (`serviceMesh.enabled: false`, `*.tls.enabled: false`) | **Plaintext** HTTP/gRPC, no transport encryption (NOTES warns about this). | reach the port — segmentation is then the only control (see NetworkPolicy). |

Authentication holds across all three modes: with `alpha.acl.enabled: true` the Alpha
client API requires login — the client authenticates as a user from the ACL accounts
Secret and sends the returned access token. With ACL off, the data API and `/alter` are
unauthenticated. Zero's `6080` admin is unauthenticated regardless of ACL, which is why
it must stay internal.

### Letting another in-cluster service connect

A client service connects only to **Alpha**, at its Service DNS name
(`<release>-dgraph-sec-alpha` by default):

```text
<release>-dgraph-sec-alpha.<namespace>.svc.cluster.local:8080   # HTTP / GraphQL / DQL
<release>-dgraph-sec-alpha.<namespace>.svc.cluster.local:9080   # gRPC
```

Use `https://` and the TLS gRPC target under native TLS. Beyond DNS, what the client
needs depends on the toggles you enabled:

- **NetworkPolicy** (`networkPolicy.enabled: true`): the chart opens Alpha `8080`/`9080`
  only to pods carrying **every** label in `networkPolicy.clientPodLabels`. Label the
  client pod to match, or add a bespoke rule to `networkPolicy.extraIngress`. The policy
  never opens Zero `5080`/`6080` or Alpha `7080` to clients, and it leaves egress
  unrestricted.
  ```yaml
  networkPolicy:
    enabled: true
    clientPodLabels:
      app.kubernetes.io/part-of: my-client-app   # this pod may reach 8080/9080
  ```
- **Service mesh** (`serviceMesh.enabled: true`): the client pod must be in the mesh
  (carry an Istio sidecar) so its traffic to Alpha is mTLS, and the mesh
  `AuthorizationPolicy` must allow the client's service-account principal. Those policies
  live in the platform mesh, not this chart.
- **Native TLS** (no mesh, `alpha.tls.enabled: true`): the client must connect over TLS
  and trust the chart CA; with `alpha.tls.clientAuthType: REQUIREANDVERIFY` it must also
  present a client certificate (basename `alpha.tls.clientName`, the
  `client.<clientName>.crt/.key` pair).
- **ACL** (`alpha.acl.enabled: true`): the client must log in as an ACL user and send the
  access token on each request.

Only Alpha `8080`/`9080` should ever be added to a client allow-list. The internal ports
(`5080`, `6080`, `7080`) stay reachable only by the dgraph pods themselves — the
NetworkPolicy's intra-cluster rule already covers that.

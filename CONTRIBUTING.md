# Contributing to charts

This repository holds the Helm charts Istari shares for running its platform —
charts a customer can consume, published to Artifactory and deployed from there.
This guide covers how to propose changes so they merge quickly and safely,
including the conventions and the local checks to run before opening a pull
request (below). (`AGENTS.md` and `CLAUDE.md` carry the same conventions for
coding agents.)

These practices come from the dgraph-sec chart post-delivery review. When you
learn something the next contributor will need, add it here.

## Ask early on #team-infra

Raise questions on `#team-infra` while you work, not after review opens. A
best-guess decision that surfaces in review costs a full round-trip; the same
question answered in chat costs minutes. Ask before you build on an assumption.

When a conversation settles an ambiguity, record the answer in this document so
the next contributor finds it here instead of asking again.

## Deliver in small, stacked pull requests

Split a large change into small pull requests that each do one thing and review
on their own. A reviewer reads a focused diff in minutes; a sprawling branch
invites stale approvals and churn.

Stack the pull requests so each builds on the one below it while keeping its own
diff small. [Graphite](https://graphite.dev/) creates and manages stacks well —
request access from IT.

### Start from a clean vendored chart, then layer by functional area

Some charts here begin life as a clean chart vendored from upstream — dgraph-sec
started as the upstream Dgraph chart. When that is the case, make the pristine
import the **first** pull request in the stack. A reviewer can then diff it
against its upstream source and trust the baseline. Add each Istari modification
as its own stacked pull request, split by functional area — monitoring,
telemetry, security hardening, mesh integration. Each layer then reviews against
a known-good base rather than as one indivisible diff.

## Harden a new chart

Plan hardening up front, not as mid-review additions. Two of these are already
standard across the charts here; the rest are not yet universal, so weigh them
against the workload rather than treating them as hard requirements.

**Expected of every chart** — the charts in this repository already meet this bar:

- [ ] **Pod and container `securityContext`** — `runAsNonRoot: true`, a non-root UID/GID, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true` (mount writable volumes where the app needs them), `capabilities.drop: [ALL]`, and `seccompProfile: RuntimeDefault`. Confirm the image actually runs as non-root before claiming it.
- [ ] **Resource requests and limits** — set CPU and memory requests (they drive scheduling and the QoS class) and limits (they cap a noisy neighbor). Base them on observed usage and make them per-environment values. Mind the trade-offs: CPU limits throttle, memory limits OOM-kill.

**Recommended, scaled to the workload** — as of June 2026 only the `dgraph-sec` chart ships these, so consider each based on what the chart does:

- [ ] **NetworkPolicy** — for a long-running service, default-deny ingress, then allow only the clients that need it, plus the mesh sidecars and the Prometheus scraper; constrain egress where you can. A baseline most workloads should carry (see the note below).
- [ ] **PodDisruptionBudget** — if the workload runs more than one replica, cap how many a voluntary disruption (node drain, upgrade) can remove via `minAvailable`/`maxUnavailable`, sized against any quorum requirement. A single-replica chart or a one-shot Job doesn't need one.
- [ ] **ServiceMonitor** — where the Prometheus Operator is available, tell it which port and path to scrape; match the `Service`'s labels, and gate it behind a values flag so the chart still installs without the operator.
- [ ] **PrometheusRule** — alongside a ServiceMonitor, ship a few meaningful alerts (availability, error rate, saturation) with severity labels, gated behind the same flag.
- [ ] **Service-account token automounting disabled** — set `automountServiceAccountToken: false` unless the workload calls the Kubernetes API; most data and app workloads don't, and a mounted token widens the blast radius. Enable it only for components that genuinely need API access.

When you skip a recommended item, say so in the PR with a reason, so the choice is visible rather than an omission.

> **Known gap (tech debt).** The charts here are uneven: only `dgraph-sec` ships a
> NetworkPolicy, PodDisruptionBudget, ServiceMonitor, or PrometheusRule —
> `istari-platform` and `istari-zitadel-configurator` ship none of the four. A
> NetworkPolicy in particular is a baseline a long-running workload should carry;
> its absence from most charts is tech debt to backfill, not a sign the bar is
> optional. Don't treat the current fleet as the standard to match.

## Validate against the target mesh early

Exercise the chart in a representative environment before final review,
including STRICT mutual-TLS and node scheduling. These expose real defects —
sidecar-less Jobs hanging under STRICT mTLS, or CronJobs landing on the wrong
node group — that otherwise surface only at rollout.

## Where a chart belongs

The split below is provisional, pending a documented org decision. When unsure,
ask in `#team-infra` before creating the chart.

- **`Istari-digital/charts`** (this repository) — **shared** charts a customer
  can consume to run the Istari platform. The repository is MIT-licensed, and it
  holds the customer-deployable platform set: `istari-platform` (the control-plane
  umbrella), `dgraph-sec` (its datastore), and `istari-zitadel-configurator` (its
  SSO setup).
- **`Istari-digital/helm-charts`** — **Istari-internal-only** charts. It holds
  internal tooling and deployments such as `customer-portal`, `istari-service`,
  `fedgenius`, the deprecated `istari-helm` v1 umbrella, and
  `istari-zitadel-configurator-overrides` (which configures Zitadel for "Istari
  internal clusters").
- The authoring repository is an ownership concern, not a deployment one: every
  distributable chart publishes to Artifactory and is consumed from there.

## Review expectations

- A first review should arrive within a few business days of a pull request
  opening.
- If a review stalls, re-request the reviewer and post in `#team-infra`.
  Escalate rather than wait.
- A security-sensitive chart should carry a second qualified reviewer, so
  neither the wait nor the review load rests on one person.

## Keep agent design, plan, and spec docs out of the repo

Do not commit coding agent design specs, implementation plans, or agent scratch notes under
`docs/`. No such documents belong in this repository. The following paths are
gitignored to reduce accidental commits: `docs/aar/`, `docs/design/`, `docs/designs/`, `docs/specs/`, `docs/plans/`, and `docs/superpowers/`.

**Tip:** With the Jira CLI or a Jira MCP tool configured, you can instruct your agent to
store the artifacts it would otherwise write under `docs/` — plans, specs,
designs — on the relevant Jira ticket instead, as the description or comments.
The ticket then holds that context durably, reviewers find it alongside the
work, and the repository stays free of agent scratch docs.

## Before you open a pull request

Run the full pre-commit suite locally — it mirrors CI and covers the standard
file checks, YAML formatting (`yamlfmt`), the `.yaml`-extension rule,
`shellcheck`, `helmlint`, and `helm-docs`:

```sh
pre-commit run --all-files
```

`helm-docs` regenerates each chart's `README.md` when you change its `Chart.yaml`
or `values.yaml`, and the hook fails the first run after such an edit. Stage the
regenerated `README.md` and run the commit again.

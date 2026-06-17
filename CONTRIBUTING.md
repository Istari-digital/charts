# Contributing to charts

This repository holds the Helm charts Istari shares for running its platform —
charts a customer can consume, published to Artifactory and deployed from there.
This guide covers how to propose changes so they merge quickly and safely. For
the toolchain, conventions, and local checks, read [`AGENTS.md`](./AGENTS.md)
and [`CLAUDE.md`](./CLAUDE.md).

These practices come from the dgraph-sec chart post-delivery review (epic
[DGR-209](https://istari.atlassian.net/browse/DGR-209)). When you learn
something the next contributor will need, add it here.

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

Most charts here begin life as a clean chart vendored from upstream — dgraph-sec
started as the upstream Dgraph chart. When that is the case, make the pristine
import the **first** pull request in the stack. A reviewer can then diff it
against its upstream source and trust the baseline. Add each Istari modification
as its own stacked pull request, split by functional area — monitoring,
telemetry, security hardening, mesh integration. Each layer then reviews against
a known-good base rather than as one indivisible diff.

## Harden a new chart

State the security primitives as planned scope up front, not as mid-review
additions. A new chart should ship:

- [ ] PodDisruptionBudget
- [ ] NetworkPolicy
- [ ] ServiceMonitor
- [ ] PrometheusRule
- [ ] Pod and container `securityContext`
- [ ] Service-account token automounting disabled
- [ ] Resource requests and limits

Treat any item you intend to skip as a decision to raise in review, with a
reason — not as an omission.

## Validate against the target mesh early

Exercise the chart in a representative environment before final review,
including STRICT mutual-TLS and node scheduling. These expose real defects —
sidecar-less Jobs hanging under STRICT mTLS, or CronJobs landing on the wrong
node group — that otherwise surface only at rollout.

## Where a chart belongs

The split below is provisional, pending a documented org decision (see
[DGR-209](https://istari.atlassian.net/browse/DGR-209)). When unsure, ask in
`#team-infra` before creating the chart.

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

These targets are proposed, pending team agreement (see
[DGR-209](https://istari.atlassian.net/browse/DGR-209)).

- A first review should arrive within a few business days of a pull request
  opening.
- If a review stalls, re-request the reviewer and post in `#team-infra`.
  Escalate rather than wait.
- A security-sensitive chart should carry a second qualified reviewer, so
  neither the wait nor the review load rests on one person.

## Keep agent design, plan, and spec docs out of the repo

Do not commit design specs, implementation plans, or agent scratch notes under
`docs/`. No plan documents belong in this repository. The
paths `docs/aar/`, `docs/design/`, `docs/designs/`, `docs/specs/`,
`docs/plans/`, and `docs/superpowers/` are gitignored to enforce this.

**Tip:** With the Jira CLI or a Jira MCP tool configured, instruct your agent to
store the artifacts it would otherwise write under `docs/` — plans, specs,
designs — on the relevant Jira ticket instead, as the description or comments.
The ticket then holds that context durably, reviewers find it alongside the
work, and the repository stays free of agent scratch docs.

## Before you open a pull request

Run the hooks locally (see [`AGENTS.md`](./AGENTS.md) for the full list):

```sh
pre-commit run --all-files
```

`helm-docs` regenerates each chart's `README.md` when you change its `Chart.yaml`
or `values.yaml`, and the hook fails the first run after such an edit. Stage the
regenerated `README.md` and run the commit again.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Helm charts Istari shares for running its platform. These are customer-consumable charts: they publish to Artifactory (the `oci://istaridigital.jfrog.io` chart registries and the `main-helm` Helm repository) and deploy from there — `helm-stack` and `dev-cluster-gitops` consume the published artifacts, never the Git source directly. Istari-internal-only charts live in `Istari-digital/helm-charts` instead; see [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the split and the rationale behind it.

## Charts
- **dgraph-sec/**: hardened Dgraph database for the Istari platform, vendored from the upstream Dgraph chart and modified.
- **istari-platform/**: umbrella chart that installs the Istari Digital Platform control plane.
- **istari-zitadel-configurator/**: configures a Zitadel instance to work with Istari.

## Chart Structure
Each chart directory holds `Chart.yaml`, `values.yaml`, `templates/`, a generated `README.md`, and (when present) `README.md.gotmpl`.

## Conventions
- Never pass secrets in chart values — they leak into ConfigMaps and other non-secret objects. Reference a Kubernetes secret via `existingSecret`/`secretKey`, or mount it as a volume.
- Prefer Chainguard FIPS images pulled through JFrog Artifactory remote repos.
- `helm-docs` keeps each chart's `README.md` in sync with its `values.yaml`; after editing `values.yaml` or `Chart.yaml`, `git add` the regenerated `README.md` and re-commit.
- YAML files use the `.yaml` extension and stay `yamlfmt` compliant; templates stay `helmlint` clean.
- A new chart must meet the hardening checklist in [`CONTRIBUTING.md`](./CONTRIBUTING.md): PodDisruptionBudget, NetworkPolicy, ServiceMonitor, PrometheusRule, pod and container `securityContext`, disabled token automounting, and resource limits.
- All files end with a trailing newline.

## Agent Working Files — Design, Plan, and Spec Docs
- Never commit agent-generated design specs, implementation plans, or scratch notes to this repository. Per Eytan's request, no plan documents live in the repo — treat them like secrets: they must never enter version control.
- The paths `docs/aar/`, `docs/design/`, `docs/designs/`, `docs/specs/`, `docs/plans/`, and `docs/superpowers/` are gitignored to enforce this.
- Store these artifacts on the relevant Jira ticket instead — as the description or comments. With the Jira CLI or a Jira MCP tool configured, write them there directly. See [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## Contributing
See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the pull-request workflow (small stacked PRs, vendor-clean-chart-first), the hardening checklist, mesh validation, review expectations, and where a chart belongs.

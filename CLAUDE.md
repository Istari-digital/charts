# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Helm charts Istari shares for running its platform. These are customer-consumable charts: CI publishes them to Artifactory — the `main-charts-local` OCI registry and the `main-helm-local` Helm repository — and deployments pull from there — `helm-stack` and `dev-cluster-gitops` consume the published artifacts, never the Git source directly. Istari-internal-only charts live in `Istari-digital/helm-charts` instead; see [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the split and the rationale behind it.

## Charts
- **dgraph-sec/**: hardened Dgraph database for the Istari platform, vendored from the upstream Dgraph chart and modified.
- **istari-platform/**: umbrella chart that installs the Istari Digital Platform control plane.
- **istari-zitadel-configurator/**: configures a Zitadel instance to work with Istari.

## Chart Structure
Each chart directory holds `Chart.yaml`, `values.yaml`, `templates/`, a generated `README.md`, and (when present) `README.md.gotmpl`.

## Conventions
Chart conventions are canonical in [`CONTRIBUTING.md`](./CONTRIBUTING.md): secrets via `existingSecret` (never in chart values), Chainguard FIPS images through JFrog Artifactory, the generated `README.md` (`helm-docs`; never hand-edit it), YAML `.yaml`/`yamlfmt`/`helmlint`, chart versioning and publishing, and the hardening checklist for new charts. Follow those sections. All files end with a trailing newline.

## Agent Working Files — Design, Plan, and Spec Docs
- Never commit agent-generated design specs, implementation plans, or scratch notes to this repository — treat them like secrets: they must never enter version control. No such documents belong in the repo.
- The paths `docs/aar/`, `docs/design/`, `docs/designs/`, `docs/specs/`, `docs/plans/`, and `docs/superpowers/` are gitignored to reduce accidental commits.
- See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for where these artifacts belong instead.

## Contributing
See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the pull-request workflow (small stacked PRs, vendor-clean-chart-first), the hardening checklist, mesh validation, review expectations, and where a chart belongs.

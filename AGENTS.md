# AGENTS.md

Instructions for AI coding agents working in this repository. This file is where shared
guidance goes. `CLAUDE.md` is a one-line import of it. `.github/copilot-instructions.md` is
the deliberate exception: it restates a subset of these rules as review triggers, because
Copilot ranks that file above this one and will not otherwise honour them — so a rule changed
here must be changed there too.

## Project

Three independently versioned Helm charts, published to a chart registry (classic and OCI)
and installed by external customers: `istari-platform` (umbrella chart for the Istari Digital
Platform control plane, with three pinned subchart dependencies),
`istari-zitadel-configurator` (configures a Zitadel instance), and `dgraph-sec` (hardened
Dgraph). Each carries its own version, publish workflow under `.github/workflows/`, and
release tag series, so commands and version rules are per chart, never repo-global.
**This repo is public.**

## Setup

```bash
pre-commit install
pre-commit install-hooks
```

See `README.md` for tool installation. `helm` and `helm-docs` must be on `PATH`; every
other hook tool is provisioned by `pre-commit` itself.

## Commands

The full gate — exactly what CI runs (`.github/workflows/pre-commit.yaml`), covering all
three charts at once, plus the docs-only and per-chart forms:

```bash
pre-commit run --all-files
pre-commit run helm-docs --all-files   # regenerate chart READMEs; rescans every chart
```

```bash
helm lint <chart>
helm template release-name <chart>   # umbrella chart needs subcharts staged, see below
```

### Rendering the umbrella chart

`helm template istari-platform` fails until the pinned subcharts are staged, with
`missing in charts/ directory`. Stage them with
`helm dependency update istari-platform`, which needs credentialed access to the chart
repository named in `istari-platform/Chart.yaml`. Both `charts/` and `Chart.lock` are
gitignored, so this leaves nothing committable.

`helm lint istari-platform` **passes without the subcharts** — it downgrades them to a
warning — so lint alone never proves the umbrella chart renders.

## Layout

Only the parts that are easy to get wrong:

- `istari-platform/templates/<service>/` — one directory per service, each with a
  `_names.tpl` and `_labels.tpl` defining `<service>.fullname`, `.selectorLabels`, and
  `.labels`. `shared/` follows the same shape without being a service; `jaeger/` holds only
  a PVC. Naming and label helpers go in those two files; a service needing a logic helper
  gets its own `_helpers.tpl` in its directory, as `api-gateway/_helpers.tpl` does for
  `api-gateway.routes` and `api-gateway.tracing.enabled`. Reserve the chart-wide
  `templates/_helpers.tpl` for helpers more than one service uses.
- `istari-platform/templates/validations.yaml` — deliberately has no leading underscore,
  so Helm evaluates it on every render and its `fail` calls cannot be skipped by disabling
  a service. It emits no manifest. Chart-wide preconditions go here; service-local ones go
  in that service's template.
- `istari-zitadel-configurator/terraform/` — real Terraform, executed in-cluster by the
  chart's hook Job. Not a workspace you plan or apply locally.
- `dgraph-sec/templates/validation/` — a hook Job, a `helm test` Pod, and a CronJob that
  run `validate.sh` against a live release. Runtime guards on a deployed cluster, not
  tests of this repository.

## Conventions

### Public artifacts

Everything this repo emits is public: PR titles and descriptions, commit messages, review
comments, and the committed files. Keep out internal hostnames, environment names, customer
names, security posture, and internal tooling detail. Incident and customer specifics belong
in the issue tracker, referenced by ticket ID only.

The published registry host and repository paths in chart metadata and image references are
the deliberate exception — customers pull from them, so they belong in the charts and are not
a leak.

### Pull requests

Every pull request title leads with its ticket ID: `<PROJECT-KEY>-<number>: Subject`, e.g.
`INF-1242: Add the thing`. Keys in use here are `INF`, `OPS`, `CPD`, `DGR`, `DPLAT`.

### Documenting values

`helm-docs` builds each README from `values.yaml`. Document a key with a `# --` comment
on the line above it. When the literal default is unhelpful, add
`# @default -- <description>`. A new key with no `# --` comment renders as an
undocumented row.

Never hand-edit `*/README.md`. Change `README.md.gotmpl` or the `values.yaml` comments
and re-run the docs hook.

### YAML hooks and Helm templates

`check-yaml` and `yamlfmt` both exclude `^([^/]+/templates/.*\.ya?ml)$`, because `{{ }}` is
not valid YAML. A template placed outside `<chart>/templates/` loses that exclusion and will
fail the YAML parse. Every YAML file must use the `.yaml` extension; a local hook fails the
commit on `.yml`. `yamlfmt` runs with `indentless_arrays=true`, `pad_line_comments=2`,
`retain_line_breaks=true` — match that in non-template YAML rather than fighting it.

### Defaults live in values.yaml

`values.yaml` is the source of truth for defaults. Do not add new `dig` or `default`
fallbacks for a key `values.yaml` already defines — the fallback becomes a second, invisible
default that drifts from the documented one. Reserve them for user-supplied structures with
no default. The many existing occurrences predate this rule: leave them unless you are
already changing that logic.

### Environment secrets

Give a **new** service a single `extraEnvSecrets: []` list and no `secretName`, the way
`apiGateway` does. This is the intended direction, not a description of the chart as it
stands: five of the seven services still pair `secretName` with `extraEnvSecrets`, that
pairing is what their templates and values comments document, and it is correct for them.
Do not retrofit them, and do not treat the pair as a defect when you meet it.

### Fail loudly at render time

When a values combination cannot produce a working release, `fail` during rendering with a
message naming the offending keys and what to set instead, rather than installing and
misbehaving later.

## Boundaries

### A chart version bump is a release, not an edit

This is the most consequential change an agent can make here. A push to `main` that
touches `{chart}/Chart.yaml` triggers that chart's publish workflow, which lints,
refuses to overwrite an already-published version, packages, audits, uploads to both the
classic and OCI registries, verifies the upload by pulling it back, and then pushes a
git tag `{chart-name}-{version}`.

- **Published versions are immutable.** A wrong number cannot be reclaimed; the only
  remedy is another bump.
- Bump in the same PR as the change it releases, and say so in the PR body. Never bump
  speculatively, to "make CI green", or as cleanup.
- Bumping a subchart also means updating its pin in `istari-platform/Chart.yaml` — itself
  a release of the umbrella chart, and only valid once the subchart is published.
- Any change to `Chart.yaml` fires the workflow, not just `version` — an edit to
  `description`, `icon`, or `maintainers` alone will trigger a publish that then fails on
  the already-published version.

### Which digit to bump

`values.yaml` is a public API: customers keep their own values files against it. **Renaming
or removing a values key is a breaking change and takes a major bump** — that is why
renaming the `identityService` key went 3.31.0 → 4.0.0, and renaming the `router` component
to `api-gateway` went 4.1.0 → 5.0.0. New keys with safe defaults are a minor bump; template
or default-value fixes that leave the interface intact are a patch.

### Paths git will silently ignore

`.gitignore` deliberately mixes anchored and unanchored patterns, and the comments there
say which is which. `Chart.lock` and `charts/` are unanchored so they match at **any**
depth, because Helm writes them inside every chart directory; `*.old` is a filename
pattern. `/manual/` and
`/scripts/` are anchored to the repo root precisely so they do not also swallow new files
in a chart's own `scripts/` directory. Preserve that distinction when editing `.gitignore`.

The failure mode is silent — an ignored file never appears in `git status`. Run
`git check-ignore -v <path>` when adding a file whose name or parent directory matches
anything in `.gitignore`.

### Live external state

`istari-zitadel-configurator` runs as a `post-install`/`post-upgrade` hook Job applying
Terraform against a live Zitadel instance, with state in a Kubernetes Secret.
`configurator.plan_only` stops after `terraform plan`; `override.enabled` substitutes
operator-supplied plan and entrypoint Secrets. Changes under its `terraform/` alter
identity-provider state on the next `helm upgrade` and need human review.

## Verification

There is no unit or integration test suite. A change is verified when:

1. `pre-commit run --all-files` is clean. This already runs `helm lint` on every chart via
   the `helmlint` hook, so a separate lint pass is only useful for reading one chart's
   output.
2. `helm template <release> <chart>` renders cleanly with default values for every chart
   touched. If you cannot stage the umbrella chart's subcharts, do not claim it verified —
   say which chart went unrendered and why.

Two things these steps do not cover, so do not describe a change to either as verified:
`istari-zitadel-configurator/terraform/` (no Terraform hook exists), and the `dgraph-sec`
validation Job and `helm test` Pod, which run against a deployed cluster rather than this
repository.

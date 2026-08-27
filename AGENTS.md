# AGENTS.md

Instructions for AI coding agents working in this repository. This file is the single
source of truth. Harness-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`)
point here instead of restating anything, so put shared guidance here.

## Project

Three independently versioned Helm charts, published to a private chart registry
(classic and OCI) and installed by external customers.

| Chart | Purpose |
| --- | --- |
| `istari-platform` | Umbrella chart for the Istari Digital Platform control plane |
| `istari-zitadel-configurator` | Configures a Zitadel instance for Istari |
| `dgraph-sec` | Hardened Dgraph database used by the platform |

Each chart carries its own version, publish workflow under `.github/workflows/`, and
release tag series, so commands and version rules are per chart, never repo-global.
`istari-platform` is an umbrella chart with three pinned subchart dependencies declared
in `istari-platform/Chart.yaml`.

**This repository is public on GitHub.** See [Public artifacts](#public-artifacts).

## Setup

```bash
pre-commit install
pre-commit install-hooks
```

See `README.md` for tool installation. `helm` and `helm-docs` must be on `PATH`; every
other hook tool is provisioned by `pre-commit` itself.

## Commands

The full gate — exactly what CI runs (`.github/workflows/pre-commit.yaml`), covering all
three charts at once:

```bash
pre-commit run --all-files
```

Regenerate the chart READMEs alone (the hook rescans every chart regardless of
arguments):

```bash
pre-commit run helm-docs --all-files
```

Lint and render, per chart:

```bash
helm lint dgraph-sec
helm lint istari-platform
helm lint istari-zitadel-configurator

helm template release-name dgraph-sec
helm template release-name istari-zitadel-configurator
helm template release-name istari-platform   # needs subcharts staged first, see below
```

### Rendering the umbrella chart

`helm template istari-platform` fails until the pinned subcharts are present in
`istari-platform/charts/`:

```
Error: ... found in Chart.yaml, but missing in charts/ directory: ...
```

Stage them with `helm dependency update istari-platform`, which needs credentialed
access to the private chart repository named in `istari-platform/Chart.yaml`. Both
`istari-platform/charts/` and `Chart.lock` are gitignored, so staging leaves nothing
committable behind.

`helm lint istari-platform` **passes without the subcharts** — it downgrades them to a
warning — so lint alone does not prove the umbrella chart renders. Any change to its
`templates/` or `values.yaml` needs a real `helm template` run.

## Layout

Only the parts that are easy to get wrong:

- `istari-platform/templates/<service>/` — one directory per service. Each owns a
  `_names.tpl` and `_labels.tpl` defining `<service>.fullname`, `.selectorLabels`, and
  `.labels`. Chart-wide helpers live only in `istari-platform/templates/_helpers.tpl`.
  Add a service-local helper to that service's `_names.tpl`/`_labels.tpl`, not to the
  chart-wide file.
- `istari-platform/templates/validations.yaml` — deliberately has no leading
  underscore, so Helm evaluates it on every render and its `fail` calls cannot be
  skipped by disabling a service. It emits no manifest. Put chart-wide preconditions
  here; put service-local ones in that service's template.
- `*/README.md` — generated. Sources are `*/README.md.gotmpl` and the field comments in
  that chart's `values.yaml`.
- `istari-zitadel-configurator/terraform/` — real Terraform, executed in-cluster by the
  chart's hook Job. Not a workspace you plan or apply locally.
- `dgraph-sec/templates/validation/` — a hook Job, a `helm test` Pod, and a CronJob that
  run `validate.sh` against a live release. Runtime guards on a deployed cluster, not
  tests of this repository.

## Conventions

### Public artifacts

Everything this repo emits is public: PR titles and descriptions, commit messages, review
comments, and the committed files. Keep out internal hostnames, environment names,
customer names, security posture, and internal tooling detail. Incident and customer
specifics belong in the issue tracker, referenced by ticket ID only.

### Pull requests

Every pull request title leads with its ticket ID, in the form `PROJ-123: Subject`.

### Documenting values

`helm-docs` builds each README from `values.yaml`. Document a key with a `# --` comment
on the line above it. When the literal default is unhelpful, add
`# @default -- <description>`. A new key with no `# --` comment renders as an
undocumented row.

Never hand-edit `*/README.md`. Change `README.md.gotmpl` or the `values.yaml` comments
and re-run the docs hook.

### YAML hooks and Helm templates

`check-yaml` and `yamlfmt` both exclude `^([^/]+/templates/.*\.ya?ml)$`, because `{{ }}`
is not valid YAML. See the `exclude:` regexes in `.pre-commit-config.yaml`. A template
placed outside `<chart>/templates/` loses that exclusion and will fail the YAML parse.

Every YAML file must use the `.yaml` extension; a local hook fails the commit on `.yml`.

`yamlfmt` runs with `indentless_arrays=true`, `pad_line_comments=2`, and
`retain_line_breaks=true`. Match that style in non-template YAML rather than fighting
the formatter.

### Defaults live in values.yaml

`values.yaml` is the source of truth for defaults. Do not add new `dig` or `default`
fallbacks for a key `values.yaml` already defines — the fallback becomes a second,
invisible default that drifts from the documented one. Reserve them for user-supplied
structures that genuinely have no default. Existing templates predate this rule; leave
them alone unless you are already changing that logic.

### Environment secrets

A new service exposes its secret-sourced environment as a single `extraEnvSecrets: []`
list. The older `secretName` plus separate-list pair is legacy: do not introduce it in
new work, and do not retrofit the services that still use it as a side effect of an
unrelated change.

### Fail loudly at render time

When a values combination cannot produce a working release, `fail` during rendering with
a message naming the offending keys and what to set instead — rather than installing and
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

### Generated files

`*/README.md` is generated. Edit the sources.

### Paths git will silently ignore

`.gitignore` deliberately mixes anchored and unanchored patterns, and the comments there
say which is which. `Chart.lock`, `charts/`, and `*.old` are unanchored so they match at
**any** depth, because Helm writes those inside every chart directory. `/manual/` and
`/scripts/` are anchored to the repo root precisely so they do not also swallow new files
in a chart's own `scripts/` directory. Preserve that distinction when editing `.gitignore`.

The failure mode is silent — an ignored file never shows up in `git status` at all. Run
`git check-ignore -v <path>` when adding a file whose name or parent directory matches
anything in `.gitignore`.

### Live external state

`istari-zitadel-configurator` runs as a `post-install`/`post-upgrade` hook Job that applies
Terraform against a live Zitadel instance and stores its state in a Kubernetes Secret.
`configurator.plan_only` stops after `terraform plan`; `override.enabled` substitutes
operator-supplied plan and entrypoint Secrets. Changes under its `terraform/` directory
alter identity-provider state on the next `helm upgrade` and need human review.

## Verification

There is no unit or integration test suite. A change is verified when:

1. `pre-commit run --all-files` is clean.
2. `helm lint <chart>` passes for every chart touched.
3. `helm template <release> <chart>` renders cleanly with default values for every chart
   touched — the umbrella chart included, with its subcharts staged.

The `dgraph-sec` validation Job and `helm test` Pod check a deployed cluster; they are not
a substitute for the three steps above.

# Copilot code review instructions

`AGENTS.md` at the repo root carries this repository's conventions and boundaries — read it
for context. This file adds only what is specific to *reviewing a diff*, restated here as
review triggers rather than as new rules.

Note for maintainers: GitHub ranks `.github/copilot-instructions.md` **above** agent
instructions (`AGENTS.md`) within repository instructions, so anything here that contradicts
`AGENTS.md` wins for Copilot. Keep the two in step.

## Flag these

**High severity**

- Internal hostnames, environment names, customer names, security posture, or internal
  tooling detail appearing in the PR title, PR description, commit message, or in
  committed files. This repository is public. Not this: the published registry host and
  repository paths in chart metadata and image references, which customers pull from and
  belong in the charts.
- **Any** change to a `{chart}/Chart.yaml` that the PR description does not identify as a
  release — the publish workflow triggers on the file, not on the `version` field, so an
  `icon`, `description`, or `maintainers` edit alone starts a publish that then fails on the
  already-published version. Also flag a subchart bump that leaves the pin in
  `istari-platform/Chart.yaml` stale, or an umbrella pin raised to a version not yet
  published.
- A renamed or removed `values.yaml` key without a **major** version bump. Customers keep
  their own values files against that interface, so removing or renaming a key breaks them.
- A hand-edited `*/README.md`. These are generated from `README.md.gotmpl` plus the
  `values.yaml` comments.
- A **newly added** file under a path `.gitignore` swallows — anything inside a `charts/`
  directory, or under the root `/manual/` or `/scripts/` — since it will be silently left
  out of the commit. Already-tracked files in those paths (`dgraph-sec/scripts/`) stay
  tracked and are fine; so are the `charts/` paths `istari-platform/Chart.yaml` depends on.
- Changes under `istari-zitadel-configurator/terraform/`. They alter live
  identity-provider state on the next upgrade and need a human reviewer.

**Normal severity**

- A pull request title that does not lead with a ticket ID: `<PROJECT-KEY>-<number>: Subject`,
  e.g. `INF-1242`. Keys in use are `INF`, `OPS`, `CPD`, `DGR`, `DPLAT`.
- A new `dig` or `default` fallback for a key that `values.yaml` already defines.
- A brand-new service adding a `secretName` key rather than a single `extraEnvSecrets` list.
  Do not flag `secretName` on the five existing services that use it, or in their templates —
  the pairing is correct there. Do flag a drive-by retrofit of one of them.
- A new `values.yaml` key with no `# --` comment above it — it renders as an
  undocumented row in the generated README.
- A values combination that can produce a broken release without a render-time `fail`.

## Do not comment on

- Diffs to `*/README.md` themselves — they are generated output.
- Indentation, quoting, or line width inside `<chart>/templates/*.yaml`. Those files are
  deliberately excluded from the YAML and formatting hooks because `{{ }}` is not valid
  YAML.
- Missing tests. This repository has no unit or integration suite by design; verification
  is the pre-commit hooks plus `helm lint` and `helm template` per chart.
- Resource requests and limits merely for existing. Concrete values are acceptable here.

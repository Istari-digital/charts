# Copilot code review instructions

`AGENTS.md` at the repo root carries this repository's conventions and boundaries — read
it for context. This file adds only what is specific to *reviewing a diff*.

## Flag these

**High severity**

- Internal hostnames, environment names, customer names, security posture, or internal
  tooling detail appearing in the PR title, PR description, commit message, or in
  committed files. This repository is public.
- A change to any `{chart}/Chart.yaml` `version` field that the PR description does not
  identify as a release. Merging it publishes an immutable chart version and pushes a git
  tag. Also flag a subchart bump that leaves the pin in `istari-platform/Chart.yaml`
  stale, or an umbrella pin raised to a version not yet published.
- A hand-edited `*/README.md`. These are generated from `README.md.gotmpl` plus the
  `values.yaml` comments.
- A committed file that references a path `.gitignore` swallows — anything under a
  `charts/` directory, or under the root `/manual/` or `/scripts/`. The referenced file
  cannot have been committed, so the reference is already broken.
- Changes under `istari-zitadel-configurator/terraform/`. They alter live
  identity-provider state on the next upgrade and need a human reviewer.

**Normal severity**

- A pull request title that does not lead with a ticket ID in the form `PROJ-123: Subject`.
- A new `dig` or `default` fallback for a key that `values.yaml` already defines.
- A new service introducing the legacy `secretName` pair instead of a single
  `extraEnvSecrets` list, or retrofitting an existing service as a drive-by change.
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

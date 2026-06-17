# AGENTS.md
Guidance for agentic coding agents working in this repository.

## Scope
- Repository type: Helm charts, shared and published to Artifactory.
- Charts (one top-level directory each): `dgraph-sec`, `istari-platform`, `istari-zitadel-configurator`.
- CI entrypoints: GitHub Actions workflows in `.github/workflows/`.
- For pull-request workflow and chart-authoring policy, read [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## Rule Files
- Cursor rules: none found (`.cursor/rules/` and `.cursorrules` are absent).
- Copilot rules: none found (`.github/copilot-instructions.md` is absent).
- Use this file, `CLAUDE.md`, `CONTRIBUTING.md`, and existing chart conventions as the source of truth.

## Toolchain
- pre-commit: required locally and in CI.
- Hooks: pre-commit-hooks (`v5.0.0`), yamlfmt (`v0.14.0`), shellcheck, helmlint, helm-docs (`v1.14.2`), plus a local `yaml-extension` check.
- Helm and helm-docs must be on PATH.

## Repository Layout
- `<chart>/`: one directory per chart — `Chart.yaml`, `values.yaml`, `templates/`, and a generated `README.md` (from `README.md.gotmpl` when present).
- `.github/`: `CODEOWNERS` and workflows.

## Build / Lint / Test Commands
There is no compile/test binary step; the quality gates are lint, `helm lint`, and `helm-docs`.

- Full local gate: `pre-commit run --all-files`
- One hook on one file: `pre-commit run <hook> --files <path>` (e.g. `pre-commit run yamlfmt --files dgraph-sec/values.yaml`)
- Lint a chart: `helm lint <chart>`
- Render a chart: `helm template <chart> -f <chart>/values.yaml`

### CI Notes
- Pull requests run pre-commit and the chart workflows in `.github/workflows/`.
- Keep local validation close to CI to avoid workflow-only failures.

## Code Style
- YAML files must use the `.yaml` extension (the `yaml-extension` hook fails on `.yml`).
- Keep YAML `yamlfmt` compliant; the hook excludes `*/templates/*` (Helm templates are not plain YAML).
- Keep templates `helmlint` clean.
- `helm-docs` regenerates a chart's `README.md` from `values.yaml` (and `README.md.gotmpl` when present) whenever `Chart.yaml` or `values.yaml` change. The hook fails the first run after such an edit — `git add` the regenerated `README.md` and re-commit.
- Never put secrets in chart values; they leak into ConfigMaps and other non-secret objects. Reference a Kubernetes secret via `existingSecret`/`secretKey`, or mount it as a volume.
- Prefer Chainguard FIPS images pulled through JFrog Artifactory remote repos.
- All files end with a trailing newline.

## Design, Plan, and Spec Docs — Do Not Commit Them
- Never add agent-generated design specs, implementation plans, or scratch notes to this repository. No such documents belong in the repo.
- The paths `docs/aar/`, `docs/design/`, `docs/designs/`, `docs/specs/`, `docs/plans/`, and `docs/superpowers/` are gitignored to reduce accidental commits.
- See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for where these artifacts belong instead.

## Agent Workflow Expectations
- Keep changes small and scoped to one chart where possible.
- Deliver a large change as small, stacked pull requests, vendoring any clean upstream chart first (see [`CONTRIBUTING.md`](./CONTRIBUTING.md)).
- A new chart must meet the hardening checklist in [`CONTRIBUTING.md`](./CONTRIBUTING.md).
- If you introduce new conventions or tools, update this file in the same change.

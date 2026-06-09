# Configurable log level and documented logging + OTEL for dgraph-sec

- **Ticket:** [DGR-237](https://istari.atlassian.net/browse/DGR-237)
- **Epic:** [DGR-209](https://istari.atlassian.net/browse/DGR-209) — Productionizing Dgraph-sec Deployment Infrastructure
- **Date:** 2026-06-09
- **Repos:** `istari-digital/charts` (chart) and `istari-digital/helm-stack` (Terraform wiring, PR #742)

## Problem

Today the only way to change Dgraph's log verbosity is to hand-append glog flags
(`-v`, `--vmodule`, `--logtostderr`) to `alpha.extraFlags` / `zero.extraFlags`. The
chart exposes no first-class logging knob, unlike Datadog, Zitadel, reloader, and
github-mcp, which all expose an explicit log-level value. The chart README documents
neither standard logging nor the existing OTEL tracing block, so an operator must read
the templates or the consuming Terraform to discover either.

## Goals

1. Add first-class, per-role logging values to the chart, wired through to the Dgraph
   command line, so operators no longer hand-edit `extraFlags` for routine logging changes.
2. Document standard (stdout/stderr) logging in the chart README: where logs go, how to
   raise verbosity, which glog options the chart exposes.
3. Document the existing OpenTelemetry tracing block in the README.
4. Wire the new log-level value through `helm-stack`'s `dgraph-sec.tf` with a
   production-sane default.

## Non-goals

- A structured/JSON log format. Dgraph emits glog text; reshaping it is out of scope.
- File-based log rotation policy. The chart exposes the glog file flags but ships no
  sidecar or volume for them.
- Changing tracing behavior. This work documents the tracing block; it does not alter it.

## Design — chart (`dgraph-sec/`)

### Per-role logging values

Add five logging keys under each role (`alpha:` and `zero:`), flat alongside the existing
`extraFlags`, `resources`, and `replicaCount`. The `tracing:` block stays a shared
top-level object; per-role placement matches how the chart already structures operational
knobs and lets an operator raise Alpha verbosity without touching Zero.

```yaml
alpha:                    # (zero: is identical)
  logLevel: normal        # named level OR raw -v integer  -> -v=N
  vmodule: ""             # glog --vmodule, e.g. "server=3,raft=2"; empty disables
  logtostderr: true       # glog --logtostderr; keep true for Kubernetes log capture
  alsologtostderr: false  # glog --alsologtostderr; also write files under logDir
  logDir: ""              # glog --log_dir; needs a writable mount; empty = glog default
  extraFlags: ""          # fallthrough for any flag not covered above
```

`logLevel` accepts a named level or a raw integer:

| `logLevel` | glog `-v` | Use |
|------------|-----------|-----|
| `normal`   | 0 | Production default — INFO/WARNING/ERROR only |
| `verbose`  | 1 | Light extra detail |
| `debug`    | 2 | Common debugging verbosity |
| `trace`    | 3 | Deep tracing |
| _integer_  | that integer | Power-user escape hatch |

glog severities (INFO/WARNING/ERROR) always reach stderr; `-v` only adds finer V-logs on
top. A named level can therefore only climb, never fall below INFO — so the chart offers
no `warn`/`error` name that would imply a suppression glog cannot deliver.

### Verbosity resolver helper

`logLevel` accepts a name or an integer, but glog's `-v` takes only an integer. A helper in
`templates/_helpers.tpl` maps a known name to its number and passes any other value
through unchanged:

```gotemplate
{{- /* Map a named log level to its glog -v integer; pass an integer through. */}}
{{- define "dgraph-sec.verbosity" -}}
  {{- $m := dict "normal" "0" "verbose" "1" "debug" "2" "trace" "3" -}}
  {{- $k := toString . -}}
  {{- index $m $k | default $k -}}
{{- end -}}
```

This follows the existing helper convention (`dgraph-sec.raftIndexFlag`,
`dgraph-sec.multiZeros`). Names are lowercase; the README documents the accepted set.

### Command-line wiring

The Alpha and Zero StatefulSet commands gain the resolved flags immediately before
`extraFlags`. Two keys (`logLevel`, `logtostderr`) emit always, so the effective value is
explicit in the pod spec; the other three emit only when set, so an unconfigured chart
produces a clean command line.

Per-role flag fragment, in order:

```gotemplate
-v={{ include "dgraph-sec.verbosity" .Values.alpha.logLevel }} --logtostderr={{ .Values.alpha.logtostderr }}
{{- if .Values.alpha.vmodule }} --vmodule={{ .Values.alpha.vmodule }}{{- end }}
{{- if .Values.alpha.alsologtostderr }} --alsologtostderr{{- end }}
{{- if .Values.alpha.logDir }} --log_dir={{ .Values.alpha.logDir }}{{- end }}
{{ .Values.alpha.extraFlags }}
```

**Ordering rule:** the resolved logging flags precede `extraFlags`, which precedes the
conditional `--trace`. Dgraph takes the last value for a repeated flag, so a `-v` in
`extraFlags` overrides `logLevel` — `extraFlags` keeps the last word as the escape hatch.

The Alpha command has one occurrence (`statefulset.yaml:202`); the Zero command has two
(`statefulset.yaml:136` for ordinal 0, `:138` with `--peer` for non-zero). Every
occurrence gets the same fragment with `zero` values.

### README documentation

`README.md.gotmpl` gains two sections; `helm-docs` regenerates `README.md`. The values
table updates automatically from the `# --` annotations on the new keys.

- **Logging** — Dgraph logs to stderr by default, captured by `kubectl logs` and the node
  collector. Raise verbosity with `logLevel`; target a subsystem with `vmodule`. Keep
  `logtostderr: true` in Kubernetes; setting it false without a writable `logDir` loses
  logs on container restart. Any glog flag not exposed goes through `extraFlags`.
- **OpenTelemetry tracing** — the `tracing` block (`enabled`, `endpoint`, `ratio`,
  per-service `alpha`/`zero` names) drives Dgraph's `--trace` superflag, exporting
  OTLP/HTTP to the Datadog agent on port 4318. Gated by `tracing.enabled`.

## Design — helm-stack (`istari-k8s-core/dgraph-sec.tf`, PR #742)

Expose the log level as a per-role Terraform variable, defaulting to the production-sane
`normal`, and reference it inside the existing `alpha`/`zero` blocks of the `helm_release`
values. The other glog keys inherit the chart defaults and can be overridden inline in the
`helm_release` values if a debugging need arises; `vmodule` is a temporary, targeted knob
unsuited to steady-state IaC, so it gets no variable.

```hcl
# variables.tf
variable "dgraph_sec_alpha_log_level" {
  type    = string
  default = "normal"
}

variable "dgraph_sec_zero_log_level" {
  type    = string
  default = "normal"
}

# dgraph-sec.tf — inside the yamlencode values
alpha = {
  # ...existing keys...
  logLevel = var.dgraph_sec_alpha_log_level
}

zero = {
  # ...existing keys...
  logLevel = var.dgraph_sec_zero_log_level
}
```

These changes land on the existing PR #742 branch (`add-dgraph-sec-chart`), not a new PR,
because PR #742 is the chart's first consumer and remains open.

## Edge cases and decisions

- **Always-emit vs. conditional.** `logLevel` and `logtostderr` carry load-bearing
  defaults, so they emit always. `vmodule`, `alsologtostderr`, and `logDir` default to
  off, so they emit only when set.
- **`logtostderr` footgun.** Flipping it false routes logs to files under `logDir`. In a
  container without a writable, mounted `logDir`, the logs vanish on restart. The default
  stays `true`, and the README warns against the change.
- **`extraFlags` override.** Placing the resolved flags before `extraFlags` lets a
  power-user `-v` in `extraFlags` win, preserving the escape hatch.
- **Niche glog flags.** `--stderrthreshold`, `--log_backtrace_at`, and `--log_link` stay
  out of the first-class set; the README points operators to `extraFlags` for them.
- **Flag spelling.** The implementation must confirm each flag against the `-sec` fork's
  `dgraph-sec --help`; glog registers `-v`, `--vmodule`, `--logtostderr`,
  `--alsologtostderr`, and `--log_dir`, but the fork is the source of truth.

## Testing and validation

- `helm template` with default values: assert `-v=0 --logtostderr=true` on both roles and
  no `--vmodule`/`--alsologtostderr`/`--log_dir`.
- `helm template` with `alpha.logLevel=debug`: assert `-v=2`.
- `helm template` with `alpha.logLevel=5`: assert `-v=5` (integer passthrough).
- `helm template` with `alpha.vmodule="server=3"`, `alpha.alsologtostderr=true`,
  `alpha.logDir=/var/log/dgraph`: assert all three flags render.
- `pre-commit run --all-files`: `helmlint` passes and `helm-docs` regenerates `README.md`
  with the new values rows and no diff.

## Rollout

1. Chart branch `DGR-237-dgraph-sec-logging-otel` off `charts` `main`: values, helper,
   StatefulSets, README. Open a PR.
2. helm-stack PR #742 branch: add the two variables and wire `logLevel`. The default
   `normal` keeps current behavior, so no environment changes until an operator opts in.
3. Chart bump and publish follow the repo's existing version workflow.

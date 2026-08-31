# Setup

## Installations

The pre-commit hooks need `helm` and `helm-docs` on your `PATH`, because they shell out to
those two. Every other hook tool, yamlfmt and shellcheck included, is provisioned by
`pre-commit` itself at the version pinned in [`.pre-commit-config.yaml`](./.pre-commit-config.yaml)
— you do not need to install those, and a newer local copy is not used.

`helm-docs` is the exception worth care. Its version is pinned in **two** independent places
that must name the same release, kept in step by hand:

- the `norwoodj/helm-docs` `rev:` in [`.pre-commit-config.yaml`](./.pre-commit-config.yaml),
  written as a git tag, **with** the leading `v`
- `helm_docs_version` in
  [`.github/workflows/pre-commit.yaml`](./.github/workflows/pre-commit.yaml), written as a
  bare version, **without** the `v`

Bumping one means bumping the other, in its own format — do not copy the `v` across. The
package managers below install whatever they currently ship, which may match neither. When
the versions differ, the docs hook regenerates the chart READMEs differently and CI fails on
the diff. To install the pinned release directly, substituting the `rev:` value verbatim
since it already carries the leading `v`:

```shell
go install github.com/norwoodj/helm-docs/cmd/helm-docs@<rev>
```

### Mac Users

```shell
brew install helm helm-docs pre-commit jq trufflehog
```

### Linux & Windows Users

To install the required packages, please use the following installation guides:
- [Helm Instructions](https://helm.sh/docs/intro/install/).
- [helm-docs Releases](https://github.com/norwoodj/helm-docs/releases).
- [jq Instructions](https://jqlang.github.io/jq/download/).
- [pre-commit Instructions](https://pre-commit.com/#install).
- [TruffleHog Instructions](https://github.com/trufflesecurity/trufflehog?tab=readme-ov-file#using-installation-script).


## Configure Pre-Commit

Set up pre-commit both globally and for this repo using the following commands:

```shell
GLOBAL_GIT_TEMPLATE_DIR=~/.git-template
git config --global init.templateDir ${GLOBAL_GIT_TEMPLATE_DIR}
pre-commit init-templatedir -t pre-commit ${GLOBAL_GIT_TEMPLATE_DIR}
pre-commit install
pre-commit install-hooks
```

## Charts

| Chart | Description |
|-------|-------------|
| [dgraph-sec](./dgraph-sec/) | Hardened Dgraph database for the Istari platform |
| [istari-platform](./istari-platform/) | Umbrella chart for the Istari Digital Platform control plane |
| [istari-zitadel-configurator](./istari-zitadel-configurator/) | Configures Zitadel instance for Istari |

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). Repository conventions, per-chart commands,
and release boundaries live in [`AGENTS.md`](./AGENTS.md).

# Setup

## Installations

The pre-commit hooks need `helm` and `helm-docs` on your `PATH`, because they shell out to
those two. Every other hook tool, yamlfmt and shellcheck included, is provisioned by
`pre-commit` itself at the version pinned in [`.pre-commit-config.yaml`](./.pre-commit-config.yaml)
— you do not need to install those, and a newer local copy is not used. Do install
`helm-docs` at the pinned version: CI installs exactly that one, and another version
produces spurious diffs in the generated chart READMEs.

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

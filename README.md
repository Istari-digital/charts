# Setup

## Installations

### Mac Users

Mac users can install the tools needed to develop in this repo using the following command:

```shell
brew bundle install --file $(git rev-parse --show-toplevel)/Brewfile
```

### Linux & Windows Users

To install the required packages, please use the following installation guides:
- [jq Instructions](https://jqlang.github.io/jq/download/).
- [pre-commit Instructions](https://pre-commit.com/#install).
- [TruffleHog Instructions](https://github.com/trufflesecurity/trufflehog?tab=readme-ov-file#using-installation-script).
- [yamlfmt Binaries](https://github.com/google/yamlfmt/releases).


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
| [istari-dgraph-sec](./istari-dgraph-sec/) | Hardened Dgraph database for the Istari platform |
| [istari-platform](./istari-platform/) | Umbrella chart for the Istari Digital Platform control plane |
| [istari-zitadel-configurator](./istari-zitadel-configurator/) | Configures Zitadel instance for Istari |

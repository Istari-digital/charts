# Changelog

Breaking changes and upgrade steps for the istari-platform chart.

## 8.0.0

The chart now gives the registry, identity, MCP and Secure Connection services the cluster-internal URL of every other service. This changes the environment variables the chart sets for them.

- `ISTARI_DIGITAL_REGISTRY_SERVICE_URL` now holds the registry's external URL, `https://<common.registryFqdn>`, and is not set when `common.registryFqdn` is empty. It used to hold the registry's cluster-internal URL, which is now in `ISTARI_DIGITAL_REGISTRY_SERVICE_INTERNAL_URL`.
- `ISTARI_DIGITAL_API_GATEWAY_SERVICE_INTERNAL_URL` is renamed `ISTARI_DIGITAL_API_INTERNAL_URL`, and is set only when `apiGateway.enabled` is `true`. The old name is no longer set.
- A value you set for any of these variables, through `env`, `extraEnvSecrets` or the Secret named by `secretName`, still takes precedence over the chart's. Remove it unless you need a different URL.
- New keys `common.registryFqdn` and `common.identityFqdn` take the scheme-less external hostnames of the registry and identity services, and are empty by default. Set them only when those services are exposed without the API gateway.
- Upgrade with `--reset-then-reuse-values`, not `--reuse-values`. `--reuse-values` keeps the stored release values, which lack the new keys, and the upgrade fails at template time.
- Earlier versions left behind a ConfigMap whose name ends in `-identity-idp-migrate-defaults` after an `identity.idpMigration` import. The chart no longer uses it, and you can delete it.

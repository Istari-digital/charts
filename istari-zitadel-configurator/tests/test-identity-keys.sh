#!/usr/bin/env bash
# Standalone test for istari-zitadel-configurator/terraform/identity-keys.tf
# (DPLAT-653). Applies the file in a throwaway root module (no Zitadel needed)
# and asserts: blob shape, ECDSA P-384, public/private separation, 32-byte
# token key, idempotent re-apply, and per-credential rotation.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cp "$here/terraform/identity-keys.tf" "$tmp/"

cat > "$tmp/test-harness.tf" <<'EOF'
variable "identity_generate_keys" {
  type    = bool
  default = true
}
variable "identity_client_integration_enabled" {
  type    = bool
  default = true
}
variable "mcp_enabled" {
  type    = bool
  default = true
}
variable "identity_key_rotation_signing_key" {
  type    = number
  default = 0
}
variable "identity_key_rotation_token_encryption_key" {
  type    = number
  default = 0
}
variable "identity_key_rotation_registry_client" {
  type    = number
  default = 0
}
variable "identity_key_rotation_scs_agent" {
  type    = number
  default = 0
}
variable "identity_key_rotation_mcp_client_secret" {
  type    = number
  default = 0
}

output "signing_key_blob" {
  value     = local.identity_signing_key_blob
  sensitive = true
}
output "token_encryption_key" {
  value     = local.identity_token_encryption_key
  sensitive = true
}
output "registry_private_blob" {
  value     = local.identity_registry_private_blob
  sensitive = true
}
output "registry_public_blob" {
  value     = local.identity_registry_public_blob
  sensitive = true
}
output "scs_private_blob" {
  value     = local.identity_scs_agent_private_blob
  sensitive = true
}
output "scs_public_blob" {
  value     = local.identity_scs_agent_public_blob
  sensitive = true
}
output "mcp_client_id" {
  value = local.identity_mcp_client_id
}
EOF

cd "$tmp"
terraform init -input=false >/dev/null
terraform apply -auto-approve -input=false >/dev/null

out() { terraform output -raw "$1"; }

# Split PEM markers so pre-commit's detect-private-key hook does not match
# this test script itself.
priv_marker="BEGIN PRIVATE ""KEY"
pub_marker="BEGIN PUBLIC ""KEY"


fail() { echo "FAIL: $*" >&2; exit 1; }

# --- blob shape + key type assertions ---
for blob_output in registry_private_blob scs_private_blob; do
  blob_json="$(out "$blob_output" | base64 -d)"
  echo "$blob_json" | jq -e '.clientId and .keyId and .key' >/dev/null || fail "$blob_output missing fields"
  echo "$blob_json" | jq -r '.key' | grep -q "$priv_marker" || fail "$blob_output not PKCS#8 private PEM"
  echo "$blob_json" | jq -r '.key' | openssl pkey -noout -text 2>/dev/null | grep -qi 'secp384r1\|P-384\|384 bit' \
    || fail "$blob_output not ECDSA P-384"
done

for blob_output in registry_public_blob scs_public_blob; do
  blob_json="$(out "$blob_output" | base64 -d)"
  echo "$blob_json" | jq -r '.key' | grep -q "$pub_marker" || fail "$blob_output not public PEM"
  if echo "$blob_json" | jq -r '.key' | grep -q "$priv_marker"; then
    fail "$blob_output leaks private material"
  fi
done

# client/key id formats (4-byte hex suffix = 8 chars)
out registry_private_blob | base64 -d | jq -r '.clientId' | grep -Eq '^registry-[0-9a-f]{8}$' || fail "registry clientId format"
out scs_private_blob | base64 -d | jq -r '.clientId' | grep -Eq '^secure-connection-[0-9a-f]{8}$' || fail "scs clientId format"
out mcp_client_id | grep -Eq '^mcp-[0-9a-f]{8}$' || fail "mcp clientId format"

# signing key blob: {keyId, key}
sk="$(out signing_key_blob | base64 -d)"
echo "$sk" | jq -e '.keyId and .key' >/dev/null || fail "signing key blob fields"
echo "$sk" | jq -r '.keyId' | grep -Eq '^signing-key-[0-9a-f]{8}$' || fail "signing keyId format"

# token encryption key: exactly 32 bytes
[ "$(out token_encryption_key | base64 -d | wc -c | tr -d ' ')" = "32" ] || fail "token key not 32 bytes"

# --- idempotency: re-plan must be empty ---
terraform plan -detailed-exitcode -input=false >/dev/null 2>&1 || fail "re-plan not empty (exit $?)"

# --- rotation: bumping one serial replaces only that credential ---
before="$(out registry_private_blob)"
sk_before="$(out signing_key_blob)"
terraform apply -auto-approve -input=false -var identity_key_rotation_registry_client=1 >/dev/null
[ "$(out registry_private_blob)" != "$before" ] || fail "registry credential did not rotate"
[ "$(out signing_key_blob)" = "$sk_before" ] || fail "signing key rotated unexpectedly"

echo "PASS: identity-keys.tf shape, idempotency, and rotation checks"

# --- secrets.yaml.tftpl render test ---------------------------------------
# Renders the template with literal values in a second throwaway root and
# asserts the gated keys appear (and disappear) with their gates, and the
# result parses as multi-document YAML.
render_tmp="$(mktemp -d)"
cp "$here/terraform/secrets.yaml.tftpl" "$render_tmp/"

render_tf() {
  local gate_keys="$1" gate_integration="$2" gate_mcp="$3"
  cat > "$render_tmp/render-test.tf" <<EOF
output "rendered" {
  value = templatefile("\${path.module}/secrets.yaml.tftpl", {
    common_domain                        = "https://zitadel.example.com"
    fe_zitadel_client_id                 = "fe-id"
    identity_client_integration_enabled  = $gate_integration
    identity_frontend_client_id          = "frontend-abcd1234"
    identity_frontend_redirect_uris      = "https://example.com"
    identity_generate_keys               = $gate_keys
    identity_mcp_client_id               = "mcp-abcd1234"
    identity_mcp_client_secret           = "mcpsecret"
    identity_mcp_enabled                 = $gate_mcp
    identity_mcp_redirect_uris           = "https://mcp.example.com/auth/callback"
    identity_registry_client_id          = "registry-abcd1234"
    identity_registry_private_blob       = "privblob"
    identity_registry_public_blob        = "pubblob"
    identity_scs_agent_private_blob      = "scspriv"
    identity_scs_agent_public_blob       = "scspub"
    identity_service_base_url            = "https://api.example.com/identity"
    identity_service_zitadel_client_id   = "id-client"
    identity_service_zitadel_manager_key = "b64managerkey"
    identity_service_zitadel_private_key = "b64key"
    identity_signing_key_blob            = "signblob"
    identity_token_encryption_key        = "tokkey"
    mcp_zitadel_client_id                = "mcp-z"
    mcp_zitadel_secret                   = "mcp-zs"
    rs_zitadel_client_id                 = "rs-id"
    rs_zitadel_project_id                = "proj"
    rs_zitadel_project_grant_id          = "grant"
    rs_zitadel_secret                    = "rs-secret"
    rs_zitadel_user_manager_secret       = "rs-um"
    scs_zitadel_project_grant_id         = "grant"
    scs_zitadel_project_id               = "proj"
    scs_zitadel_role_name                = "role"
    scs_zitadel_user_id                  = "scs-user"
    scs_zitadel_user_manager_secret      = "scs-um"
    zitadel_domain                       = "https://zitadel.example.com"
    zitadel_org_id                       = "org"
  })
}
EOF
  (cd "$render_tmp" && terraform init -backend=false -input=false >/dev/null \
    && terraform apply -auto-approve -input=false >/dev/null)
  (cd "$render_tmp" && terraform output -raw rendered)
}

rendered_on="$(render_tf true true true)"
echo "$rendered_on" | python3 -c "import yaml,sys; list(yaml.safe_load_all(sys.stdin))" || fail "rendered secrets not valid YAML (gates on)"
for key in FILE_SERVICE_IDENTITY_ROUTER_SECRET \
           ISTARI_DIGITAL_IDENTITY_SERVICE_SIGNING_KEY \
           ISTARI_DIGITAL_IDENTITY_SERVICE_REGISTRY_CLIENT \
           ISTARI_DIGITAL_IDENTITY_SERVICE_AGENT_PROVISIONING_CLIENT_IDS \
           VITE_IDENTITY_ROUTER_CLIENT_ID \
           ISTARI_DIGITAL_IDENTITY_ROUTER_AGENT_KEY \
           ISTARI_DIGITAL_IDENTITY_SERVICE_MCP_CLIENT_ID; do
  echo "$rendered_on" | grep -q "$key" || fail "gated key $key missing when gates on"
done

rendered_off="$(render_tf false false false)"
echo "$rendered_off" | python3 -c "import yaml,sys; list(yaml.safe_load_all(sys.stdin))" || fail "rendered secrets not valid YAML (gates off)"
for key in FILE_SERVICE_IDENTITY_ROUTER_SECRET \
           ISTARI_DIGITAL_IDENTITY_SERVICE_SIGNING_KEY \
           ISTARI_DIGITAL_IDENTITY_SERVICE_REGISTRY_CLIENT \
           VITE_IDENTITY_ROUTER_CLIENT_ID \
           ISTARI_DIGITAL_IDENTITY_ROUTER_AGENT_KEY \
           ISTARI_DIGITAL_IDENTITY_SERVICE_MCP_CLIENT_ID; do
  if echo "$rendered_off" | grep -q "$key"; then
    fail "gated key $key present when gates off"
  fi
done
rm -rf "$render_tmp"

echo "PASS: secrets.yaml.tftpl render gating checks"

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

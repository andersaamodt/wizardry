#!/bin/sh
# Test coverage for validate-ssh-key spell:
# - Shows usage with --help
# - Accepts valid RSA key format
# - Accepts valid ed25519 key format
# - Rejects invalid key format

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/cantrips/validate-ssh-key" --help
  assert_success || return 1
  assert_output_contains "Usage: validate-ssh-key" || return 1
}

test_accepts_rsa_key() {
  # Sample RSA key format (not real key)
  run_spell "spells/cantrips/validate-ssh-key" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB user@host"
  assert_success || return 1
}

test_accepts_ed25519_key() {
  # Sample ed25519 key format (not real key)
  run_spell "spells/cantrips/validate-ssh-key" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI user@host"
  assert_success || return 1
}

test_rejects_invalid_format() {
  run_spell "spells/cantrips/validate-ssh-key" "not-a-valid-key"
  assert_failure || return 1
}

test_requires_argument() {
  run_spell "spells/cantrips/validate-ssh-key"
  assert_failure || return 1
  assert_error_contains "key required" || return 1
}

run_test_case "validate-ssh-key shows usage text" test_help
run_test_case "validate-ssh-key accepts RSA keys" test_accepts_rsa_key
run_test_case "validate-ssh-key accepts ed25519 keys" test_accepts_ed25519_key
run_test_case "validate-ssh-key rejects invalid format" test_rejects_invalid_format
run_test_case "validate-ssh-key requires argument" test_requires_argument

finish_tests

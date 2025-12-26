#!/bin/sh
# Test coverage for validate-ssh-key spell:
# - Shows usage with --help
# - Accepts valid RSA key format
# - Accepts valid ed25519 key format
# - Rejects invalid key format

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/validate-ssh-key" --help
  _assert_success || return 1
  _assert_output_contains "Usage: validate-ssh-key" || return 1
}

test_accepts_rsa_key() {
  # Sample RSA key format (not real key)
  _run_spell "spells/cantrips/validate-ssh-key" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB user@host"
  _assert_success || return 1
}

test_accepts_ed25519_key() {
  # Sample ed25519 key format (not real key)
  _run_spell "spells/cantrips/validate-ssh-key" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI user@host"
  _assert_success || return 1
}

test_rejects_invalid_format() {
  _run_spell "spells/cantrips/validate-ssh-key" "not-a-valid-key"
  _assert_failure || return 1
}

test_requires_argument() {
  _run_spell "spells/cantrips/validate-ssh-key"
  _assert_failure || return 1
  _assert_error_contains "key required" || return 1
}

_run_test_case "validate-ssh-key shows usage text" test_help
_run_test_case "validate-ssh-key accepts RSA keys" test_accepts_rsa_key
_run_test_case "validate-ssh-key accepts ed25519 keys" test_accepts_ed25519_key
_run_test_case "validate-ssh-key rejects invalid format" test_rejects_invalid_format
_run_test_case "validate-ssh-key requires argument" test_requires_argument


# Test via source-then-invoke pattern  
validate_ssh_key_help_via_sourcing() {
  _run_sourced_spell validate-ssh-key --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "validate-ssh-key works via source-then-invoke" validate_ssh_key_help_via_sourcing
_finish_tests

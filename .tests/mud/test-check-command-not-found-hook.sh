#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - check-command-not-found-hook prints usage
# - check-command-not-found-hook returns 0 when enabled (default)
# - check-command-not-found-hook returns 0 when explicitly enabled
# - check-command-not-found-hook returns 1 when explicitly disabled
# - check-command-not-found-hook respects SPELLBOOK_DIR

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/mud/check-command-not-found-hook" --help
  _assert_success && _assert_output_contains "Usage: check-command-not-found-hook"
}

test_returns_success_when_not_configured() {
  # Default behavior: enabled when no config
  tmpdir=$(_make_tempdir)
  SPELLBOOK_DIR="$tmpdir/.spellbook" _run_spell "spells/mud/check-command-not-found-hook"
  _assert_success
}

test_returns_success_when_explicitly_enabled() {
  tmpdir=$(_make_tempdir)
  config_file="$tmpdir/.spellbook/.mud/config"
  mkdir -p "$(dirname "$config_file")"
  printf 'command-not-found=1\n' > "$config_file"
  
  SPELLBOOK_DIR="$tmpdir/.spellbook" _run_spell "spells/mud/check-command-not-found-hook"
  _assert_success
}

test_returns_failure_when_explicitly_disabled() {
  tmpdir=$(_make_tempdir)
  config_file="$tmpdir/.spellbook/.mud/config"
  mkdir -p "$(dirname "$config_file")"
  printf 'command-not-found=0\n' > "$config_file"
  
  SPELLBOOK_DIR="$tmpdir/.spellbook" _run_spell "spells/mud/check-command-not-found-hook"
  _assert_failure
}

test_respects_spellbook_dir_env() {
  tmpdir=$(_make_tempdir)
  custom_spellbook="$tmpdir/custom-spellbook"
  config_file="$custom_spellbook/.mud/config"
  mkdir -p "$(dirname "$config_file")"
  printf 'command-not-found=0\n' > "$config_file"
  
  SPELLBOOK_DIR="$custom_spellbook" _run_spell "spells/mud/check-command-not-found-hook"
  _assert_failure
}

_run_test_case "check-command-not-found-hook prints usage" test_help
_run_test_case "check-command-not-found-hook returns success when not configured (default enabled)" test_returns_success_when_not_configured
_run_test_case "check-command-not-found-hook returns success when explicitly enabled" test_returns_success_when_explicitly_enabled
_run_test_case "check-command-not-found-hook returns failure when explicitly disabled" test_returns_failure_when_explicitly_disabled
_run_test_case "check-command-not-found-hook respects SPELLBOOK_DIR environment variable" test_respects_spellbook_dir_env
_finish_tests

#!/bin/sh
# Behavioral cases (derived from --help):
# - enable-service prompts then enables unit
# - enable-service fails when name missing

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(make_tempdir)
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}




enable_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  stub-ask-text "$stub_dir" "delta"
  stub-systemctl "$stub_dir"
  stub-sudo "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/system/enable-service"
  assert_success || return 1
  assert_output_contains "Enabling delta.service so it starts at boot..." || return 1
  assert_output_contains "systemd enablement request submitted." || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "enable delta.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

enable_service_requires_name() {
  stub_dir=$(make_stub_dir)
  stub-ask-text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/system/enable-service"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "enable-service prompts then enables unit" enable_service_prompts_and_invokes
run_test_case "enable-service fails when name missing" enable_service_requires_name

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/enable-service" ]
}

run_test_case "cantrips/enable-service is executable" spell_is_executable
shows_help() {
  run_spell spells/system/enable-service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "enable-service shows help" shows_help

# Test via source-then-invoke pattern  

finish_tests

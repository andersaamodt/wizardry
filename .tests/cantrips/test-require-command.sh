#!/bin/sh
# Behavioral cases (derived from --help):
# - require-command succeeds when command exists
# - require-command reports missing commands with default guidance
# - require-command accepts a custom failure message
# - require-command requires at least one argument

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

require_command_succeeds_when_available() {
  _run_spell "spells/cantrips/require-command" sh
  _assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
}

require_command_reports_missing_with_default_message() {
  _run_spell "spells/cantrips/require-command" definitely-not-a-real-command
  _assert_failure || return 1
  _assert_error_contains "require-command: The 'definitely-not-a-real-command' command is required." || return 1
  _assert_error_contains "core-menu" || return 1
}

require_command_supports_custom_message() {
  _run_spell "spells/cantrips/require-command" missing-helper "custom install instructions"
  _assert_failure || return 1
  _assert_error_contains "custom install instructions" || return 1
}

require_command_installs_when_helper_available() {
  tmp=$(_make_tempdir)

  cat >"$tmp/install-missing" <<'SH'
#!/bin/sh
touch "$STUB_DIR/missing"
chmod +x "$STUB_DIR/missing"
SH
  chmod +x "$tmp/install-missing"

  _run_cmd env PATH="$tmp:$PATH" STUB_DIR="$tmp" REQUIRE_COMMAND_ASSUME_YES=1 \
    "$ROOT_DIR/spells/cantrips/require-command" missing

  _assert_success && _assert_path_exists "$tmp/missing"
}

require_command_requires_arguments() {
  _run_spell "spells/cantrips/require-command"
  _assert_failure || return 1
  _assert_error_contains "Usage: require-command" || return 1
}

_run_test_case "require-command succeeds when command exists" require_command_succeeds_when_available
_run_test_case "require-command reports missing commands with default guidance" require_command_reports_missing_with_default_message
_run_test_case "require-command accepts a custom failure message" require_command_supports_custom_message
_run_test_case "require-command requires at least one argument" require_command_requires_arguments
_run_test_case "require-command installs when helper is available" require_command_installs_when_helper_available

_finish_tests

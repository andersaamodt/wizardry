#!/bin/sh
# Behavioral cases (derived from --help):
# - assertions helpers pass through on success
# - assert_equal reports mismatch and exits

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_assertions_succeed_for_happy_path() {
  tmp=$(_make_tempdir)
  script="$tmp/assert_ok.sh"
  cat >"$script" <<SCRIPT
#!/bin/sh
ROOT_DIR="$ROOT_DIR"
. "$ROOT_DIR/spells/cantrips/assertions"
assert_equal "a" "a"
assert_output "printf foo" "foo"
_assert_success "exit 0"
_assert_failure "exit 1"
SCRIPT
  chmod +x "$script"
  _run_cmd sh "$script"
  _assert_success
}

test_assert_equal_failure_exits_with_message() {
  tmp=$(_make_tempdir)
  script="$tmp/assert_fail.sh"
  cat >"$script" <<SCRIPT
#!/bin/sh
ROOT_DIR="$ROOT_DIR"
. "$ROOT_DIR/spells/cantrips/assertions"
assert_equal "one" "two"
SCRIPT
  chmod +x "$script"
  _run_cmd sh "$script"
  _assert_failure && _assert_error_contains "Assertion failed: 'one' != 'two'"
}

_run_test_case "assertions helpers pass through on success" test_assertions_succeed_for_happy_path
_run_test_case "assert_equal reports mismatch and exits" test_assert_equal_failure_exits_with_message
spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/assertions" ]
}

_run_test_case "cantrips/assertions is executable" spell_is_executable
_finish_tests

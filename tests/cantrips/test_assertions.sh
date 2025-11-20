#!/bin/sh
# Behavioral cases (derived from --help):
# - assertions helpers pass through on success
# - assert_equal reports mismatch and exits

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_assertions_succeed_for_happy_path() {
  tmp=$(make_tempdir)
  script="$tmp/assert_ok.sh"
  cat >"$script" <<SCRIPT
#!/bin/sh
ROOT_DIR="$ROOT_DIR"
. "$ROOT_DIR/spells/cantrips/assertions"
assert_equal "a" "a"
assert_output "printf foo" "foo"
assert_success "exit 0"
assert_failure "exit 1"
SCRIPT
  chmod +x "$script"
  run_cmd sh "$script"
  assert_success
}

test_assert_equal_failure_exits_with_message() {
  tmp=$(make_tempdir)
  script="$tmp/assert_fail.sh"
  cat >"$script" <<SCRIPT
#!/bin/sh
ROOT_DIR="$ROOT_DIR"
. "$ROOT_DIR/spells/cantrips/assertions"
assert_equal "one" "two"
SCRIPT
  chmod +x "$script"
  run_cmd sh "$script"
  assert_failure && assert_error_contains "Assertion failed: 'one' != 'two'"
}

run_test_case "assertions helpers pass through on success" test_assertions_succeed_for_happy_path
run_test_case "assert_equal reports mismatch and exits" test_assert_equal_failure_exits_with_message
finish_tests

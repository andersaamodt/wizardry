#!/bin/sh
set -eu

# shellcheck source=../../spells/.imps/test/test-bootstrap
# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

install_attr_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/core/install-attr" ]
}

install_attr_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/core/install-attr" ]
}

install_attr_shows_help() {
  run_spell spells/.arcana/core/install-attr --help
  assert_success || return 1
  assert_output_contains "extended attribute" || return 1
}

run_test_case "install-attr has content" install_attr_has_content
run_test_case "install-attr is executable" install_attr_is_executable
run_test_case "install-attr shows help" install_attr_shows_help
finish_tests

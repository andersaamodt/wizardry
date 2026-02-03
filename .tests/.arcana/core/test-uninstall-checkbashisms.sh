#!/bin/sh
# Test uninstall-checkbashisms spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_exists() {
  [ -f "$ROOT_DIR/spells/.arcana/core/uninstall-checkbashisms" ]
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/core/uninstall-checkbashisms" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/core/uninstall-checkbashisms" ]
}

shows_help() {
  run_spell spells/.arcana/core/uninstall-checkbashisms --help
  assert_success || return 1
  assert_output_contains "uninstall-checkbashisms" || return 1
}

run_test_case "uninstall-checkbashisms spell exists" spell_exists
run_test_case "uninstall-checkbashisms is executable" spell_is_executable
run_test_case "uninstall-checkbashisms has content" spell_has_content
run_test_case "uninstall-checkbashisms shows help" shows_help

finish_tests

#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_simple() {
  printf "ROOT_DIR=%s\n" "$ROOT_DIR" >&2
  printf "Running: run_spell wards/defcon --help\n" >&2
  run_spell "wards/defcon" --help
  printf "STATUS=%s\n" "$STATUS" >&2
  printf "OUTPUT=%s\n" "$OUTPUT" >&2
  printf "ERROR=%s\n" "$ERROR" >&2
  assert_success || return 1
  assert_output_contains "Usage: defcon" || return 1
}

run_test_case "simple test" test_simple
finish_tests

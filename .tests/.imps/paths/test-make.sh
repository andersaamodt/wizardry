#!/bin/sh
# Tests for the 'make' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_make_dir() {
  tmpdir="$WIZARDRY_TMPDIR/make_test_$$"
  "$ROOT_DIR/spells/.imps/paths/make" dir "$tmpdir"
  if [ -d "$tmpdir" ]; then
    rm -rf "$tmpdir"
    return 0
  fi
  TEST_FAILURE_REASON="make dir should create directory"
  return 1
}

test_make_unknown_type_fails() {
  run_spell spells/.imps/paths/make unknown "$WIZARDRY_TMPDIR/test_$$"
  assert_failure
}

run_test_case "make dir creates directory" test_make_dir
run_test_case "make unknown type fails" test_make_unknown_type_fails

finish_tests

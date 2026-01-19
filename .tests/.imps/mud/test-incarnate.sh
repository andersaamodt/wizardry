#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.imps/mud/incarnate" --help
  assert_success && assert_output_contains "Usage: incarnate"
}

test_incarnate_basic() {
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/custom-spellbook"
  export PATH="$ROOT_DIR/spells/.imps/mud:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/fs:$PATH"
  
  mkdir -p "$SPELLBOOK_DIR"
  
  cd "$tmpdir"
  run_spell "spells/.imps/mud/incarnate"
  assert_success && assert_output_contains "Avatar initialized"
}

run_test_case "incarnate prints usage" test_help
run_test_case "incarnate creates avatar" test_incarnate_basic

finish_tests

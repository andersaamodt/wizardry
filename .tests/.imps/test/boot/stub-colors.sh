#!/bin/sh
# Test stub-colors imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_colors "$tmpdir"
  [ -x "$tmpdir/colors" ]
}

test_stub_provides_empty_colors() {
  tmpdir=$(make_tempdir)
  stub_colors "$tmpdir"
  . "$tmpdir/colors"
  [ -z "$RESET" ] && [ -z "$CYAN" ] && [ -z "$GREY" ]
}

run_test_case "stub-colors creates executable" test_creates_stub
run_test_case "stub-colors provides empty color variables" test_stub_provides_empty_colors

finish_tests

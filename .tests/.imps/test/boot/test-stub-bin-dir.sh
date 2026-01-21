#!/bin/sh
# Test stub-bin-dir imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_bin_directory() {
  bindir=$(stub_bin_dir)
  [ -d "$bindir" ]
}

test_returns_bin_path() {
  bindir=$(stub_bin_dir)
  case "$bindir" in
    */bin) : ;;
    *) return 1 ;;
  esac
}

run_test_case "stub-bin-dir creates bin directory" test_creates_bin_directory
run_test_case "stub-bin-dir returns path ending in /bin" test_returns_bin_path

finish_tests

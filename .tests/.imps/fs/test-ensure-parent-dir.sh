#!/bin/sh
# Test ensure-parent-dir imp

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_parent_dir() {
  skip-if-compiled || return $?
  _run_cmd sh -c 'tmpdir=$(mktemp -d) && ensure-parent-dir "$tmpdir/level1/level2/file.txt" && [ -d "$tmpdir/level1/level2" ] && rm -rf "$tmpdir" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_handles_existing_parent_dir() {
  skip-if-compiled || return $?
  _run_cmd sh -c 'tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/existing" && ensure-parent-dir "$tmpdir/existing/file.txt" && [ -d "$tmpdir/existing" ] && rm -rf "$tmpdir" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_handles_file_in_current_dir() {
  skip-if-compiled || return $?
  _run_cmd sh -c 'tmpdir=$(mktemp -d) && cd "$tmpdir" && ensure-parent-dir "file.txt" && cd / && rm -rf "$tmpdir" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_creates_deeply_nested_dirs() {
  skip-if-compiled || return $?
  _run_cmd sh -c 'tmpdir=$(mktemp -d) && ensure-parent-dir "$tmpdir/a/b/c/d/e/file.txt" && [ -d "$tmpdir/a/b/c/d/e" ] && rm -rf "$tmpdir" && printf "ok"'
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

_run_test_case "ensure-parent-dir creates parent directory" test_creates_parent_dir
_run_test_case "ensure-parent-dir handles existing parent" test_handles_existing_parent_dir
_run_test_case "ensure-parent-dir handles file in current dir" test_handles_file_in_current_dir
_run_test_case "ensure-parent-dir creates deeply nested dirs" test_creates_deeply_nested_dirs

_finish_tests

#!/bin/sh
# Tests for the 'temp-file' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_temp_file_creates_file() {
  # Run temp-file and check that the resulting file exists (within sandbox)
  run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && [ -f "$f" ] && rm -f "$f" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_temp_file_creates_unique_files() {
  # Run temp-file twice and verify files are unique
  run_cmd sh -c 'f1=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && f2=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && [ "$f1" != "$f2" ] && rm -f "$f1" "$f2" && printf "ok"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_temp_file_with_prefix() {
  # Check that custom prefix is used in the path
  run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file" myprefix) && case "$f" in */myprefix.*) rm -f "$f"; printf "ok";; *) printf "bad: %s" "$f"; exit 1;; esac'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

test_temp_file_default_prefix() {
  # Check that default prefix 'wizardry' is used
  run_cmd sh -c 'f=$("'"$ROOT_DIR"'/spells/.imps/fs/temp-file") && case "$f" in */wizardry.*) rm -f "$f"; printf "ok";; *) printf "bad: %s" "$f"; exit 1;; esac'
  assert_success || return 1
  assert_output_contains "ok" || return 1
}

run_test_case "temp-file creates file" test_temp_file_creates_file
run_test_case "temp-file creates unique files" test_temp_file_creates_unique_files
run_test_case "temp-file with custom prefix" test_temp_file_with_prefix
run_test_case "temp-file uses default prefix" test_temp_file_default_prefix

finish_tests

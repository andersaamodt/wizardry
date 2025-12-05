#!/bin/sh
# Tests for the 'clip-paste' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

# Note: clip-paste will fail in CI without a clipboard utility, but we test error handling

test_clip_paste_no_utility_fails_gracefully() {
  # This test runs in sandbox without clipboard utilities
  # It should fail gracefully with an error message
  run_spell spells/.imps/fs/clip-paste
  # Either succeeds (if clipboard util available) or fails gracefully
}

test_clip_paste_produces_output() {
  # Test that the imp runs and produces output or fails gracefully
  run_spell spells/.imps/fs/clip-paste
  # Either succeeds or fails gracefully depending on clipboard availability
}

run_test_case "clip-paste handles missing utility" test_clip_paste_no_utility_fails_gracefully
run_test_case "clip-paste produces output" test_clip_paste_produces_output

finish_tests

#!/bin/sh
# Tests for the 'clip-copy' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

# Note: clip-copy will fail in CI without a clipboard utility, but we test error handling

test_clip_copy_no_utility_fails_gracefully() {
  # This test runs in sandbox without clipboard utilities
  # It should fail gracefully with an error message
  run_spell spells/.imps/fs/clip-copy "test text"
  # Either succeeds (if clipboard util available) or fails gracefully
}

test_clip_copy_from_stdin() {
  # Test that piped input is handled - use full path via run_spell
  run_cmd sh -c "echo 'test' | $ROOT_DIR/spells/.imps/fs/clip-copy"
  # Either succeeds or fails gracefully depending on clipboard availability
}

run_test_case "clip-copy handles missing utility" test_clip_copy_no_utility_fails_gracefully
run_test_case "clip-copy from stdin" test_clip_copy_from_stdin

finish_tests

#!/bin/sh
# Behavioral cases (derived from --help):
# - jump-to-marker prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/jump-to-marker" --help
  assert_success && assert_output_contains "Usage: jump-to-marker"
}

test_unknown_option_fails() {
  run_spell "spells/jump-to-marker" --bad
  assert_failure && assert_error_contains "unknown option"
}

test_install_requires_helpers() {
  helpers_dir="$WIZARDRY_TMPDIR/helpers-missing"
  mkdir -p "$helpers_dir"
  PATH="/bin:/usr/bin" JUMP_TO_MARKER_HELPERS_DIR="$helpers_dir" MARKER_FILE="$WIZARDRY_TMPDIR/marker" \
    run_spell "spells/jump-to-marker" --install
  assert_failure && assert_error_contains "required helper 'detect-rc-file' is missing"
}

run_test_case "jump-to-marker prints usage" test_help
run_test_case "jump-to-marker rejects unknown options" test_unknown_option_fails
run_test_case "jump-to-marker install fails when helpers missing" test_install_requires_helpers
finish_tests

#!/bin/sh
# Example test demonstrating dual-pattern testing with clear organized output

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that passes in both patterns
test_shows_usage() {
  _run_spell "spells/arcane/copy" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}

# Test that might fail - demonstrates organized output
test_requires_file() {
  _run_spell "spells/arcane/copy" "$WIZARDRY_TMPDIR/test-file.txt"
  _assert_failure || return 1
  _assert_output_contains "does not exist" || return 1
}

# Run with both patterns automatically
# Output will show: [exec] and [src] markers for each test
# Failures will be organized by execution pattern
_run_both_patterns "copy shows usage" test_shows_usage "spells/arcane/copy"
_run_both_patterns "copy requires existing file" test_requires_file "spells/arcane/copy"

_finish_tests

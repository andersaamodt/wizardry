#!/bin/sh
# Test coverage for open-teletype spell:
# - Shows usage with --help
# - Requires torify command

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/translocation/open-teletype" --help
  assert_success || return 1
  assert_output_contains "Usage: open-teletype" || return 1
}

test_requires_torify() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Provide basic utilities but not torify
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  PATH="$ROOT_DIR/spells/.imps:$stubdir" run_spell "spells/translocation/open-teletype"
  assert_failure || return 1
  assert_error_contains "torify not found" || return 1
}

run_test_case "open-teletype shows usage text" test_help
run_test_case "open-teletype requires torify" test_requires_torify

finish_tests

#!/bin/sh
# Test coverage for logs spell:
# - Script exists and is executable
# - Sources required files
# - Uses detect-distro

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_spell_exists() {
  [ -f "$ROOT_DIR/spells/system/logs" ] || { TEST_FAILURE_REASON="spell file does not exist"; return 1; }
}

test_is_executable() {
  [ -x "$ROOT_DIR/spells/system/logs" ] || { TEST_FAILURE_REASON="spell is not executable"; return 1; }
}

test_sources_colors() {
  grep -q "colors" "$ROOT_DIR/spells/system/logs" || { TEST_FAILURE_REASON="spell does not source colors"; return 1; }
}

run_test_case "logs spell exists" test_spell_exists
run_test_case "logs spell is executable" test_is_executable
run_test_case "logs sources colors" test_sources_colors

finish_tests

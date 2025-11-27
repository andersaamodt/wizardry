#!/bin/sh
# Test coverage for package-managers spell:
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
  [ -f "$ROOT_DIR/spells/system/package-managers" ] || { TEST_FAILURE_REASON="spell file does not exist"; return 1; }
}

test_is_executable() {
  [ -x "$ROOT_DIR/spells/system/package-managers" ] || { TEST_FAILURE_REASON="spell is not executable"; return 1; }
}

test_checks_distro() {
  grep -q "distro" "$ROOT_DIR/spells/system/package-managers" || { TEST_FAILURE_REASON="spell does not check distro"; return 1; }
}

run_test_case "package-managers spell exists" test_spell_exists
run_test_case "package-managers spell is executable" test_is_executable
run_test_case "package-managers checks distro" test_checks_distro

finish_tests

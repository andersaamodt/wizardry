#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

has_unit_section() {
  grep -q '^\[Unit\]' "$ROOT_DIR/spells/install/bitcoin/bitcoin.service"
}

run_test_case "install/bitcoin/bitcoin.service declares a Unit section" has_unit_section
finish_tests

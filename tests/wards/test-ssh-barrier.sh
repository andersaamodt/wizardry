#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_exists() {
  [ -f "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

run_test_case "wards/ssh-barrier exists" spell_exists
run_test_case "wards/ssh-barrier has content" spell_has_content
finish_tests

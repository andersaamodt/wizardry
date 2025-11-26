#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/test-magic" ]
}

shows_help() {
  run_spell spells/system/test-magic --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "system/test-magic is executable" spell_is_executable
run_test_case "system/test-magic shows help" shows_help
spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/system/test-magic" | grep -q "^#!"
}

run_test_case "system/test-magic has shebang" spell_has_shebang
finish_tests

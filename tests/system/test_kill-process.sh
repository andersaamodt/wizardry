#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/system/kill-process" ]
}

run_test_case "system/kill-process is executable" spell_is_executable
finish_tests

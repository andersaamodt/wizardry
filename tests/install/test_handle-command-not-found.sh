#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

spell_exists() {
  [ -f "$ROOT_DIR/spells/install/handle-command-not-found" ]
}

run_test_case "install/handle-command-not-found exists" spell_exists
finish_tests

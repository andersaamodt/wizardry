#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_exists() {
  [ -f "$ROOT_DIR/spells/install/core/handle-command-not-found" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/handle-command-not-found" ]
}

run_test_case "install/handle-command-not-found exists" spell_exists
run_test_case "install/handle-command-not-found has content" spell_has_content

shows_help() {
  run_spell spells/install/core/handle-command-not-found --help
  true
}

run_test_case "handle-command-not-found shows help" shows_help
finish_tests

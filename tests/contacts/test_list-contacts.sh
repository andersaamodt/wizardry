#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/contacts/list-contacts" ]
}

run_test_case "contacts/list-contacts is executable" spell_is_executable
finish_tests

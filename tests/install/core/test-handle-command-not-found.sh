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
spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/install/core/handle-command-not-found" | grep -q "^#!"
}

run_test_case "install/core/handle-command-not-found has shebang" spell_has_shebang
finish_tests

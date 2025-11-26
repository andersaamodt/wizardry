#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/configure-tor-bridge" ]
}

run_test_case "install/tor/configure-tor-bridge is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/configure-tor-bridge" ]
}

run_test_case "install/tor/configure-tor-bridge has content" spell_has_content
spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/install/tor/configure-tor-bridge" | grep -q "^#!"
}

run_test_case "install/tor/configure-tor-bridge has shebang" spell_has_shebang
finish_tests

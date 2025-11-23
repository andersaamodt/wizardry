#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

spell_is_executable() {
  spell="$ROOT_DIR/spells/install/tor/setup-tor"
  if [ ! -f "$spell" ]; then
    echo "Expected $spell to exist" >&2
    return 1
  fi

  if [ ! -x "$spell" ]; then
    echo "Expected $spell to be executable; run 'chmod +x \"$spell\"'" >&2
    return 1
  fi
}

run_test_case "install/tor/setup-tor is executable" spell_is_executable
finish_tests

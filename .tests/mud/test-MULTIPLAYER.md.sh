#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

file_exists() {
  [ -f "$ROOT_DIR/spells/mud/MULTIPLAYER.md" ]
}

run_test_case "MULTIPLAYER.md exists" file_exists

file_has_content() {
  [ -s "$ROOT_DIR/spells/mud/MULTIPLAYER.md" ]
}

run_test_case "MULTIPLAYER.md has content" file_has_content

finish_tests

#!/bin/sh
# Behavioral cases:
# - doppelganger requires a target directory argument
# - doppelganger creates compiled wizardry clone
# - doppelganger --help shows usage

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/spellcraft/doppelganger" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_requires_target_directory() {
  _run_spell "spells/spellcraft/doppelganger"
  _assert_failure && _assert_error_contains "target directory required"
}

test_creates_compiled_wizardry() {
  workdir=$(_make_tempdir)
  target="$workdir/wizardry-clone"
  
  _run_spell "spells/spellcraft/doppelganger" "$target"
  _assert_success || return 1
  
  # Check directory structure exists
  [ -d "$target" ] || { TEST_FAILURE_REASON="target directory not created"; return 1; }
  [ -d "$target/spells" ] || { TEST_FAILURE_REASON="spells directory not created"; return 1; }
  [ -f "$target/LICENSE" ] || { TEST_FAILURE_REASON="LICENSE not copied"; return 1; }
  
  # Check that compiled spells exist
  [ -f "$target/spells/cantrips/hash" ] || { TEST_FAILURE_REASON="hash spell not compiled"; return 1; }
  
  # Check that .git and .github are excluded
  [ ! -d "$target/.git" ] || { TEST_FAILURE_REASON=".git should be excluded"; return 1; }
  [ ! -d "$target/.github" ] || { TEST_FAILURE_REASON=".github should be excluded"; return 1; }
}

_run_test_case "doppelganger prints usage" test_help
_run_test_case "doppelganger requires target directory" test_requires_target_directory
_run_test_case "doppelganger creates compiled wizardry" test_creates_compiled_wizardry

_finish_tests

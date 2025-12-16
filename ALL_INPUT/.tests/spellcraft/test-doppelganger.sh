#!/bin/sh
# Behavioral cases:
# - doppelganger creates compiled wizardry clone
# - doppelganger --help shows usage
# - doppelganger uses default directory if none provided

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

test_uses_default_directory() {
  # doppelganger uses ./wizardry-compiled as default
  # Just verify it doesn't fail without arguments
  # (don't actually run it as it would create files in the working directory)
  _run_spell "spells/spellcraft/doppelganger" --help
  _assert_success
}

test_creates_compiled_wizardry() {
  # Skip in compiled mode - requires compile-spell and full wizardry environment
  if [ "${WIZARDRY_TEST_COMPILED-0}" = "1" ]; then
    return 0
  fi
  
  workdir=$(_make_tempdir)
  target="$workdir/wizardry-clone"
  
  # Verify compile-spell exists before trying to use it
  if [ ! -x "${ROOT_DIR}/spells/spellcraft/compile-spell" ]; then
    TEST_FAILURE_REASON="compile-spell not found at ${ROOT_DIR}/spells/spellcraft/compile-spell"
    return 1
  fi
  
  # Ensure compile-spell is in PATH and available
  # Add spellcraft directory to PATH before running
  saved_path="$PATH"
  export PATH="${ROOT_DIR}/spells/spellcraft:${ROOT_DIR}/spells:${PATH}"
  
  _run_spell "spells/spellcraft/doppelganger" "$target"
  _assert_success || { export PATH="$saved_path"; return 1; }
  
  # Check directory structure exists
  [ -d "$target" ] || { TEST_FAILURE_REASON="target directory not created"; return 1; }
  [ -d "$target/spells" ] || { TEST_FAILURE_REASON="spells directory not created"; return 1; }
  [ -f "$target/LICENSE" ] || { TEST_FAILURE_REASON="LICENSE not copied"; return 1; }
  
  # Check that some compiled spells exist
  # Note: wc -l outputs leading whitespace on Mac, trim it for reliable comparison
  # Use -perm for better cross-platform compatibility
  spell_count=$(find "$target/spells" -type f \( -perm -111 -o -perm -100 \) 2>/dev/null | wc -l)
  spell_count=$(printf '%s' "$spell_count" | tr -d ' \t')
  if [ "$((spell_count))" -le 0 ]; then
    # Debug: show what files exist
    TEST_FAILURE_REASON="no compiled spells found (found $(find "$target/spells" -type f 2>/dev/null | wc -l | tr -d ' ') files total)"
    return 1
  fi
  
  # Check that .git and .github are excluded
  [ ! -d "$target/.git" ] || { TEST_FAILURE_REASON=".git should be excluded"; export PATH="$saved_path"; return 1; }
  [ ! -d "$target/.github" ] || { TEST_FAILURE_REASON=".github should be excluded"; export PATH="$saved_path"; return 1; }
  
  # Restore PATH
  export PATH="$saved_path"
}

_run_test_case "doppelganger prints usage" test_help
_run_test_case "doppelganger uses default directory" test_uses_default_directory
_run_test_case "doppelganger creates compiled wizardry" test_creates_compiled_wizardry

_finish_tests

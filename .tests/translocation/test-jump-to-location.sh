#!/bin/sh
# Test jump-to-location synonym (alias for jump-to-marker)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_synonym_defined_in_defaults() {
  # Check that jump-to-location is defined in default synonyms
  if ! grep -q "jump-to-location.*jump-to-marker" "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"; then
    printf 'jump-to-location synonym not found in invoke-thesaurus\n' >&2
    return 1
  fi
}

test_no_spell_file_exists() {
  # Verify the spell file was deleted (it's now just a synonym)
  if [ -f "$ROOT_DIR/spells/translocation/jump-to-location" ]; then
    printf 'jump-to-location spell file should not exist (it is now a synonym)\n' >&2
    return 1
  fi
}

run_test_case "jump-to-location defined in default synonyms" test_synonym_defined_in_defaults
run_test_case "jump-to-location spell file deleted" test_no_spell_file_exists
finish_tests

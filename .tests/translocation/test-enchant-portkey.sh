#!/bin/sh
# Test coverage for enchant-portkey spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file
# - Rejects extra operands
# - Rejects missing destinations before writing metadata

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/enchant-portkey" --help
  assert_success || return 1
  assert_output_contains "Usage: enchant-portkey" || return 1
}

test_requires_argument() {
  run_spell "spells/translocation/enchant-portkey"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/translocation/enchant-portkey" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_rejects_extra_operands() {
  tmpdir=$(make_tempdir)
  target=$tmpdir/item
  destination=$tmpdir/destination
  stubdir=$tmpdir/bin
  mkdir -p "$destination" "$stubdir"
  : > "$target"
  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'exit 0'
  } > "$stubdir/enchant"
  chmod +x "$stubdir/enchant"

  PATH="$stubdir:$PATH" run_spell "spells/translocation/enchant-portkey" "$target" "$destination" extra
  assert_failure || return 1
  assert_error_contains "at most two" || return 1
}

test_rejects_missing_destination_without_enchanting() {
  tmpdir=$(make_tempdir)
  target=$tmpdir/item
  missing=$tmpdir/missing-destination
  stubdir=$tmpdir/bin
  log=$tmpdir/enchant.log
  mkdir -p "$stubdir"
  : > "$target"
  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' "printf '%s\n' called >> '$log'"
  } > "$stubdir/enchant"
  chmod +x "$stubdir/enchant"

  PATH="$stubdir:$PATH" run_spell "spells/translocation/enchant-portkey" "$target" "$missing"
  assert_failure || return 1
  assert_error_contains "destination does not exist" || return 1
  if [ -f "$log" ]; then
    TEST_FAILURE_REASON="enchant-portkey wrote metadata for missing destination"
    return 1
  fi
}

run_test_case "enchant-portkey shows usage text" test_help
run_test_case "enchant-portkey requires file argument" test_requires_argument
run_test_case "enchant-portkey fails on missing file" test_fails_on_missing_file
run_test_case "enchant-portkey rejects extra operands" test_rejects_extra_operands
run_test_case "enchant-portkey rejects missing destination before enchanting" test_rejects_missing_destination_without_enchanting


# Test via source-then-invoke pattern  

finish_tests

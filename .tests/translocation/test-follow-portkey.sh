#!/bin/sh
# Test coverage for follow-portkey spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file
# - Rejects extra operands
# - Fails without printing a cd command when destination is gone

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/follow-portkey" --help
  assert_success || return 1
  assert_output_contains "Usage: follow-portkey" || return 1
}

test_requires_argument() {
  run_spell "spells/translocation/follow-portkey"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/translocation/follow-portkey" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_rejects_extra_operands() {
  tmpdir=$(make_tempdir)
  portkey=$tmpdir/portkey
  stubdir=$tmpdir/bin
  mkdir -p "$stubdir"
  : > "$portkey"
  {
    printf '%s\n' '#!/bin/sh'
    printf 'printf '\''%%s\\n'\'' %s\n' "'$tmpdir'"
  } > "$stubdir/read-magic"
  chmod +x "$stubdir/read-magic"

  PATH="$stubdir:$PATH" run_spell "spells/translocation/follow-portkey" "$portkey" extra
  assert_failure || return 1
  assert_error_contains "exactly one" || return 1
}

test_fails_on_missing_destination_without_cd() {
  tmpdir=$(make_tempdir)
  portkey=$tmpdir/portkey
  missing=$tmpdir/missing-destination
  stubdir=$tmpdir/bin
  mkdir -p "$stubdir"
  : > "$portkey"
  {
    printf '%s\n' '#!/bin/sh'
    printf 'printf '\''%%s\\n'\'' %s\n' "'$missing'"
  } > "$stubdir/read-magic"
  chmod +x "$stubdir/read-magic"

  PATH="$stubdir:$PATH" run_spell "spells/translocation/follow-portkey" "$portkey"
  assert_failure || return 1
  assert_error_contains "destination does not exist" || return 1
  case "$OUTPUT" in
    *'cd "'*)
      TEST_FAILURE_REASON="follow-portkey printed eval-able cd output after failure"
      return 1
      ;;
  esac
}

run_test_case "follow-portkey shows usage text" test_help
run_test_case "follow-portkey requires file argument" test_requires_argument
run_test_case "follow-portkey fails on missing file" test_fails_on_missing_file
run_test_case "follow-portkey rejects extra operands" test_rejects_extra_operands
run_test_case "follow-portkey fails without cd when destination is missing" test_fails_on_missing_destination_without_cd


# Test via source-then-invoke pattern  

finish_tests

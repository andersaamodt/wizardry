#!/bin/sh
# Integration test for invoke-wizardry
# Verifies that sourcing invoke-wizardry makes spell functions available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

invoke_wizardry_completes_without_parse_errors() {
  # Create a script that sources invoke-wizardry and captures output
  test_script=$(mktemp "${WIZARDRY_TMPDIR}/test-invoke.XXXXXX")
  cat > "$test_script" <<'SCRIPT'
#!/bin/sh
set +eu
export WIZARDRY_DIR="$1"
export WIZARDRY_LOAD_ALL=1
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" 2>&1
SCRIPT
  chmod +x "$test_script"
  
  OUTPUT=$("$test_script" "$ROOT_DIR" 2>&1)
  STATUS=$?
  
  rm -f "$test_script"
  
  # Should complete successfully
  if [ "$STATUS" -ne 0 ]; then
    TEST_FAILURE_REASON="invoke-wizardry exited with status $STATUS"
    return 1
  fi
  
  # Should NOT contain parse errors
  case "$OUTPUT" in
    *"parse error"*)
      TEST_FAILURE_REASON="invoke-wizardry produced parse errors"
      return 1
      ;;
  esac
  
  # Should report completion
  case "$OUTPUT" in
    *"invoke-wizardry complete"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="invoke-wizardry did not complete (missing 'complete' message)"
      return 1
      ;;
  esac
}

menu_function_available_after_sourcing() {
  # The _run_sourced_spell helper does this for us
  _run_sourced_spell menu --help
  
  _assert_success || return 1
  _assert_error_contains "Usage: menu" || return 1
}

forall_function_available_after_sourcing() {
  tmpdir=$(_make_tempdir)
  printf 'test' > "$tmpdir/file.txt"
  
  RUN_CMD_WORKDIR=$tmpdir _run_sourced_spell forall cat
  
  _assert_success || return 1
  _assert_output_contains "file.txt" || return 1
  _assert_output_contains "   test" || return 1
}

copy_function_available_after_sourcing() {
  tmpdir=$(_make_tempdir)
  printf 'original' > "$tmpdir/source.txt"
  
  RUN_CMD_WORKDIR=$tmpdir _run_sourced_spell copy "$tmpdir/source.txt" "$tmpdir/dest.txt"
  
  _assert_success || return 1
  _assert_path_exists "$tmpdir/dest.txt" || return 1
}

_run_test_case "invoke-wizardry completes without parse errors" invoke_wizardry_completes_without_parse_errors
_run_test_case "menu function available after sourcing invoke-wizardry" menu_function_available_after_sourcing
_run_test_case "forall function available after sourcing invoke-wizardry" forall_function_available_after_sourcing
_run_test_case "copy function available after sourcing invoke-wizardry" copy_function_available_after_sourcing

_finish_tests

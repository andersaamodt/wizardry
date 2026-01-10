#!/bin/sh
# Test coverage for blink spell:
# - Shows usage with --help
# - Successfully blinks to a random directory from root
# - Respects --home flag
# - Validates max-depth parameter

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/blink" --help
  assert_success || return 1
  assert_output_contains "Usage: . blink" || return 1
  assert_output_contains "--home" || return 1
}

test_blink_from_root() {
  # Test that blink works from root (default behavior)
  # Source blink in a subshell and verify it changes directory
  tmpscript=$(make_tempdir)/test.sh
  
  # Export needed variables
  export WIZARDRY_IMPS_PATH
  export ROOT_DIR
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Create test script - use double quotes to expand variables
  cat > "$tmpscript" <<TESTSCRIPT
#!/bin/sh
export PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin"
export WIZARDRY_DIR="$ROOT_DIR"
export ROOT_DIR="$ROOT_DIR"
start_dir=\$(pwd)
. "$ROOT_DIR/spells/translocation/blink" 1 >/dev/null 2>&1
end_dir=\$(pwd)
if [ "\$start_dir" != "\$end_dir" ]; then
  exit 0
else
  exit 1
fi
TESTSCRIPT
  
  chmod +x "$tmpscript"
  sh "$tmpscript"
}

test_blink_with_home_flag() {
  # Create a test directory structure
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/test/dir1"
  mkdir -p "$tmpdir/test/dir2"
  mkdir -p "$tmpdir/test/dir3"
  
  # Export needed variables
  export WIZARDRY_IMPS_PATH
  export ROOT_DIR
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Create test script - use double quotes to expand variables
  tmpscript="$tmpdir/test.sh"
  cat > "$tmpscript" <<TESTSCRIPT
#!/bin/sh
export PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin"
export WIZARDRY_DIR="$ROOT_DIR"
export ROOT_DIR="$ROOT_DIR"
export HOME="$tmpdir"
cd "\$HOME"
. "$ROOT_DIR/spells/translocation/blink" --home 1 >/dev/null 2>&1
end_dir=\$(pwd)
case "\$end_dir" in
  "$tmpdir"*) exit 0 ;;
  *) exit 1 ;;
esac
TESTSCRIPT
  
  chmod +x "$tmpscript"
  sh "$tmpscript"
}

test_rejects_invalid_depth() {
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin"
  export PATH
  run_cmd sh -c "set -- abc; . \"$ROOT_DIR/spells/translocation/blink\""
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

test_rejects_zero_depth() {
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin"
  export PATH
  run_cmd sh -c "set -- 0; . \"$ROOT_DIR/spells/translocation/blink\""
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

run_test_case "blink shows usage text" test_help
run_test_case "blink teleports from root by default" test_blink_from_root
run_test_case "blink respects --home flag" test_blink_with_home_flag
run_test_case "blink rejects invalid depth parameter" test_rejects_invalid_depth
run_test_case "blink rejects zero depth" test_rejects_zero_depth

finish_tests
